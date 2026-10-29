package com.tecverse.app.service.impl;

import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.tecverse.app.dto.TicketOtpSendRequest;
import com.tecverse.app.entity.TicketMobileOtp;
import com.tecverse.app.repository.TicketMobileOtpRepository;
import com.tecverse.app.repository.TicketRegistrationRepository;
import com.tecverse.app.service.MailDeliveryService;
import com.tecverse.app.service.TicketOtpService;
import com.tecverse.app.util.SMSServices;
import com.tecverse.app.util.OtpConsoleLogger;
import com.tecverse.app.util.ValidationUtil;

@Service
public class TicketOtpServiceImpl implements TicketOtpService {

    private static final Logger log = LoggerFactory.getLogger(TicketOtpServiceImpl.class);

    @Value("${tecverse.otp.log-to-console:false}")
    private boolean logOtpsToConsole;

    private static final Duration OTP_VALIDITY = Duration.ofMinutes(5);
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int MAX_OTP_ATTEMPTS = 5;

    private final MailDeliveryService mailDeliveryService;
    private final TicketRegistrationRepository registrationRepository;
    private final Map<String, OtpEntry> otpStore = new ConcurrentHashMap<>();
    private final Map<String, LocalDateTime> verifiedEmails = new ConcurrentHashMap<>();
    private final Map<String, OtpEntry> passwordResetOtps = new ConcurrentHashMap<>();
    private final Map<String, Integer> passwordResetOtpAttempts = new ConcurrentHashMap<>();
    private final Map<String, ResetGrant> verifiedPasswordResets = new ConcurrentHashMap<>();
    private final TicketMobileOtpRepository mobileOtpRepository;
    private final SMSServices smsServices;
    private final String smsUsername;
    private final String smsPassword;
    private final String smsSenderId;
    private final String smsSecureKey;
    private final String smsTemplateId;

    public TicketOtpServiceImpl(MailDeliveryService mailDeliveryService, TicketRegistrationRepository registrationRepository,
                                TicketMobileOtpRepository mobileOtpRepository,
                                @Value("${tecverse.sms.url}") String smsUrl,
                                @Value("${tecverse.sms.username}") String smsUsername,
                                @Value("${tecverse.sms.password}") String smsPassword,
                                @Value("${tecverse.sms.sender-id}") String smsSenderId,
                                @Value("${tecverse.sms.secure-key}") String smsSecureKey,
                                @Value("${tecverse.sms.template-id}") String smsTemplateId) {
        this.mailDeliveryService = mailDeliveryService;
        this.registrationRepository = registrationRepository;
        this.mobileOtpRepository = mobileOtpRepository;
        this.smsServices = new SMSServices(smsUrl);
        this.smsUsername = smsUsername;
        this.smsPassword = smsPassword;
        this.smsSenderId = smsSenderId;
        this.smsSecureKey = smsSecureKey;
        this.smsTemplateId = smsTemplateId;
    }

    @Override
    public void sendMobileOtp(String phone) {
        String mobile = ValidationUtil.normalizeIndianMobile(phone);
        if (registrationRepository.existsByPhone(mobile)) throw new IllegalArgumentException("This phone number is already registered.");
        sendMobileOtpForFlow(mobile);
    }

    @Override
    public void sendExhibitorMobileOtp(String phone) {
        // Exhibitor registration is independent from attendee ticket registration.
        sendMobileOtpForFlow(ValidationUtil.normalizeIndianMobile(phone));
    }

    private void sendMobileOtpForFlow(String mobile) {
        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));
        // Must match the licensed DLT template word for word, or the gateway rejects the SMS.
        String msg = "Dear Patron, Use OTP " + otp + " to verify your mobile number and complete your registration on the Tec-Verse Portal. Please do not share this OTP with anyone. Team Tec-Verse";
        String output = smsServices.sendOtpSMS(smsUsername, smsPassword, msg, smsSenderId, mobile, smsSecureKey, smsTemplateId);
        if (output == null || !output.contains(SMSServices.SUCCESS_MARKER)) {
            log.error("OTP SMS sending FAILED for mobile ending {}: {}", mobile.substring(Math.max(0, mobile.length() - 4)), output);
            throw new IllegalStateException("SMS Gateway error. Please try again later.");
        }
        OtpConsoleLogger.printIfEnabled(logOtpsToConsole, "Mobile number verification", otp);
        // Saving with the same mobile replaces any earlier OTP for that number (and resets attempts).
        mobileOtpRepository.save(new TicketMobileOtp(mobile, hashMobileOtp(mobile, otp), Instant.now().plus(OTP_VALIDITY)));
    }

    // noRollbackFor: failed-attempt counts and deletions must be committed even though we then throw.
    @Override
    @Transactional(noRollbackFor = IllegalArgumentException.class)
    public void verifyMobileOtp(String phone, String otp) {
        String mobile = ValidationUtil.normalizeIndianMobile(phone);
        TicketMobileOtp entry = mobileOtpRepository.findByMobileForUpdate(mobile)
                .orElseThrow(() -> new IllegalArgumentException("Please request a new OTP."));
        if (Instant.now().isAfter(entry.getExpiresAt())) {
            mobileOtpRepository.delete(entry);
            throw new IllegalArgumentException("OTP has expired. Please request a new OTP.");
        }
        if (otp == null || !MessageDigest.isEqual(entry.getOtpHash().getBytes(java.nio.charset.StandardCharsets.UTF_8),
                hashMobileOtp(mobile, otp.trim()).getBytes(java.nio.charset.StandardCharsets.UTF_8))) {
            if (entry.incrementFailedAttempts() >= MAX_OTP_ATTEMPTS) {
                mobileOtpRepository.delete(entry);
                throw new IllegalArgumentException("Too many incorrect OTP attempts. Please request a new OTP.");
            }
            throw new IllegalArgumentException("Incorrect OTP. Please try again.");
        }
        // Correct OTP: delete it so it can never be used again.
        mobileOtpRepository.delete(entry);
    }

    @Scheduled(fixedRate = 3_600_000)
    @Transactional
    public void purgeExpiredMobileOtps() {
        mobileOtpRepository.deleteExpired(Instant.now());
    }

    private static String hashMobileOtp(String mobile, String otp) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest((mobile + ":" + otp).getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (java.security.NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 unavailable", ex);
        }
    }

    @Override
    public void sendOtp(TicketOtpSendRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (registrationRepository.existsByEmail(email)) throw new IllegalArgumentException("This email is already registered.");
        String normalizedPhone = ValidationUtil.normalizeIndianMobile(request.getPhone());
        if (registrationRepository.existsByPhone(normalizedPhone)) throw new IllegalArgumentException("This phone number is already registered.");
        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));
        OtpEntry entry = new OtpEntry(otp, LocalDateTime.now().plus(OTP_VALIDITY));
        otpStore.put(email, entry);

        // Wait for SMTP so the form can show an actionable error when the mail server is down.
        // On failure, invalidate this OTP before returning the delivery error to the caller.
        try {
            boolean sent = mailDeliveryService.sendSimple(
                    email,
                    "Tec-Verse ticket verification OTP",
                    buildMessage(request, otp),
                    "Ticket OTP"
            );
            if (!sent) throw new IllegalStateException("Mail server is temporarily unavailable. Please try again later.");
            OtpConsoleLogger.printIfEnabled(logOtpsToConsole, "Ticket email verification", otp);
        } catch (RuntimeException ex) {
            otpStore.remove(email, entry);
            log.warn("Ticket email OTP delivery failed; the affected OTP was invalidated.", ex);
            throw ex;
        }
    }

    @Override
    public void verifyOtp(String email, String otp) {
        String normalizedEmail = normalizeEmail(email);
        OtpEntry entry = otpStore.get(normalizedEmail);
        if (entry == null) {
            throw new IllegalArgumentException("Please request a new OTP.");
        }
        if (LocalDateTime.now().isAfter(entry.expiresAt())) {
            otpStore.remove(normalizedEmail);
            throw new IllegalArgumentException("OTP has expired. Please request a new OTP.");
        }
        if (otp == null || !MessageDigest.isEqual(entry.otp().getBytes(java.nio.charset.StandardCharsets.UTF_8),
                otp.trim().getBytes(java.nio.charset.StandardCharsets.UTF_8))) {
            if (entry.failedAttempts().incrementAndGet() >= MAX_OTP_ATTEMPTS) {
                otpStore.remove(normalizedEmail, entry);
                throw new IllegalArgumentException("Too many incorrect OTP attempts. Please request a new OTP.");
            }
            throw new IllegalArgumentException("Incorrect OTP. Please try again.");
        }
        if (!otpStore.remove(normalizedEmail, entry)) {
            throw new IllegalArgumentException("Please request a new OTP.");
        }
        verifiedEmails.put(normalizedEmail, LocalDateTime.now().plus(Duration.ofMinutes(30)));
    }

    @Override
    public boolean isEmailVerified(String email) {
        String key=normalizeEmail(email); LocalDateTime until=verifiedEmails.get(key);
        if(until==null) return false;
        if(LocalDateTime.now().isAfter(until)){verifiedEmails.remove(key); return false;}
        return true;
    }

    public void sendPasswordResetOtp(String email) {
        String normalizedEmail = normalizeEmail(email);
        if (normalizedEmail.isBlank() || !registrationRepository.existsByEmail(normalizedEmail)) {
            return;
        }
        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));
        passwordResetOtpAttempts.remove(normalizedEmail);
        verifiedPasswordResets.remove(normalizedEmail);
        passwordResetOtps.put(normalizedEmail, new OtpEntry(otp, LocalDateTime.now().plus(OTP_VALIDITY)));
        if (!mailDeliveryService.sendSimple(normalizedEmail, "Tec-Verse app password reset OTP",
                "Your Tec-Verse app password reset OTP is " + otp + ". It is valid for 5 minutes.\n\nTec-verse Team",
                "Mobile password reset OTP")) {
            passwordResetOtps.remove(normalizedEmail);
            passwordResetOtpAttempts.remove(normalizedEmail);
            throw new IllegalStateException("Unable to send email right now. Please try again later.");
        }
        OtpConsoleLogger.printIfEnabled(logOtpsToConsole, "App password reset", otp);
    }

    public synchronized String verifyPasswordResetOtp(String email, String otp) {
        String normalizedEmail = normalizeEmail(email);
        OtpEntry entry = passwordResetOtps.get(normalizedEmail);
        if (entry == null) throw new IllegalArgumentException("Please request a new OTP.");
        if (LocalDateTime.now().isAfter(entry.expiresAt())) {
            passwordResetOtps.remove(normalizedEmail);
            passwordResetOtpAttempts.remove(normalizedEmail);
            throw new IllegalArgumentException("OTP has expired. Please request a new OTP.");
        }
        if (otp == null || !MessageDigest.isEqual(entry.otp().getBytes(java.nio.charset.StandardCharsets.UTF_8),
                otp.trim().getBytes(java.nio.charset.StandardCharsets.UTF_8))) {
            int attempts = passwordResetOtpAttempts.merge(normalizedEmail, 1, Integer::sum);
            if (attempts >= 5) {
                passwordResetOtps.remove(normalizedEmail);
                passwordResetOtpAttempts.remove(normalizedEmail);
                throw new IllegalArgumentException("Too many incorrect OTP attempts. Request a new OTP.");
            }
            throw new IllegalArgumentException("Incorrect OTP. Please try again.");
        }
        passwordResetOtps.remove(normalizedEmail);
        passwordResetOtpAttempts.remove(normalizedEmail);
        // A single-use random token proves this caller passed the OTP step; knowing the email alone is not enough.
        byte[] tokenBytes = new byte[32];
        RANDOM.nextBytes(tokenBytes);
        String resetToken = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
        verifiedPasswordResets.put(normalizedEmail, new ResetGrant(resetToken, LocalDateTime.now().plus(Duration.ofMinutes(10))));
        return resetToken;
    }

    public boolean consumePasswordResetVerification(String email, String resetToken) {
        String normalizedEmail = normalizeEmail(email);
        ResetGrant grant = verifiedPasswordResets.get(normalizedEmail);
        if (grant == null || resetToken == null || resetToken.isBlank()) return false;
        if (LocalDateTime.now().isAfter(grant.expiresAt())) {
            verifiedPasswordResets.remove(normalizedEmail, grant);
            return false;
        }
        if (!MessageDigest.isEqual(grant.token().getBytes(java.nio.charset.StandardCharsets.UTF_8),
                resetToken.trim().getBytes(java.nio.charset.StandardCharsets.UTF_8))) {
            return false;
        }
        return verifiedPasswordResets.remove(normalizedEmail, grant);
    }

    private record ResetGrant(String token, LocalDateTime expiresAt) {
    }

    public void consumeEmailVerification(String email) { verifiedEmails.remove(normalizeEmail(email)); }

    private String buildMessage(TicketOtpSendRequest request, String otp) {
        String name = ValidationUtil.sanitize(request.getFullName());
        String passType = request.getPassType() == null || request.getPassType().isBlank()
                ? "ticket"
                : ValidationUtil.sanitize(request.getPassType());

       return "Hello " + name + ",\n\n"
        + "Thank you for registering for Tec-Verse 2026.\n\n"
        + "To complete your registration, please use the "
        + "One-Time Password (OTP) below to verify your account.\n\n"
        + "Verification Code: " + otp + "\n\n"
        + "This code is valid for 5 minutes. For your security, "
        + "please do not share this code with anyone.\n\n"
        + "If you did not initiate this registration, "
        + "please disregard this message.\n\n"
        + "Regards,\n"
        + "Tec-Verse 2026 Team";
    }

    private static String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }

    private record OtpEntry(String otp, LocalDateTime expiresAt, AtomicInteger failedAttempts) {
        OtpEntry(String otp, LocalDateTime expiresAt) {
            this(otp, expiresAt, new AtomicInteger());
        }
    }
}
