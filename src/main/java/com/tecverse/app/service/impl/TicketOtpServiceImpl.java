package com.tecverse.app.service.impl;

import java.security.SecureRandom;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Service;

import com.tecverse.app.dto.TicketOtpSendRequest;
import com.tecverse.app.service.TicketOtpService;
import com.tecverse.app.repository.TicketRegistrationRepository;
import com.tecverse.app.service.MailDeliveryService;
import com.tecverse.app.util.ValidationUtil;

@Service
public class TicketOtpServiceImpl implements TicketOtpService {

    private static final Duration OTP_VALIDITY = Duration.ofMinutes(5);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final MailDeliveryService mailDeliveryService;
    private final TicketRegistrationRepository registrationRepository;
    private final Map<String, OtpEntry> otpStore = new ConcurrentHashMap<>();
    private final Map<String, LocalDateTime> verifiedEmails = new ConcurrentHashMap<>();
    private final Map<String, OtpEntry> passwordResetOtps = new ConcurrentHashMap<>();
    private final Map<String, Integer> passwordResetOtpAttempts = new ConcurrentHashMap<>();
    private final Map<String, LocalDateTime> verifiedPasswordResets = new ConcurrentHashMap<>();

    public TicketOtpServiceImpl(MailDeliveryService mailDeliveryService, TicketRegistrationRepository registrationRepository) {
        this.mailDeliveryService = mailDeliveryService;
        this.registrationRepository = registrationRepository;
    }

    @Override
    public void sendOtp(TicketOtpSendRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (registrationRepository.existsByEmail(email)) throw new IllegalArgumentException("This email is already registered.");
        String normalizedPhone = ValidationUtil.normalizeIndianMobile(request.getPhone());
        if (registrationRepository.existsByPhone(normalizedPhone)) throw new IllegalArgumentException("This phone number is already registered.");
        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));
        otpStore.put(email, new OtpEntry(otp, LocalDateTime.now().plus(OTP_VALIDITY)));

        try {
            boolean sent = mailDeliveryService.sendSimple(
                    email,
                    "Tec-verse ticket verification OTP",
                    buildMessage(request, otp),
                    "Ticket OTP"
            );
            if (!sent) {
                throw new IllegalStateException("Unable to send email right now. Please try again later.");
            }
        } catch (IllegalStateException ex) {
            otpStore.remove(email);
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
        if (!entry.otp().equals(otp)) {
            throw new IllegalArgumentException("Incorrect OTP. Please try again.");
        }
        otpStore.remove(normalizedEmail);
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
        if (!mailDeliveryService.sendSimple(normalizedEmail, "Tec-verse app password reset OTP",
                "Your Tec-verse app password reset OTP is " + otp + ". It is valid for 5 minutes.\n\nTec-verse Team",
                "Mobile password reset OTP")) {
            passwordResetOtps.remove(normalizedEmail);
            passwordResetOtpAttempts.remove(normalizedEmail);
            throw new IllegalStateException("Unable to send email right now. Please try again later.");
        }
    }

    public synchronized void verifyPasswordResetOtp(String email, String otp) {
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
        verifiedPasswordResets.put(normalizedEmail, LocalDateTime.now().plus(Duration.ofMinutes(10)));
    }

    public boolean consumePasswordResetVerification(String email) {
        String normalizedEmail = normalizeEmail(email);
        LocalDateTime until = verifiedPasswordResets.remove(normalizedEmail);
        return until != null && !LocalDateTime.now().isAfter(until);
    }

    public void consumeEmailVerification(String email) { verifiedEmails.remove(normalizeEmail(email)); }

    private String buildMessage(TicketOtpSendRequest request, String otp) {
        String name = ValidationUtil.sanitize(request.getFullName());
        String passType = request.getPassType() == null || request.getPassType().isBlank()
                ? "ticket"
                : ValidationUtil.sanitize(request.getPassType());

        return "Hello " + name + ",\n\n"
                + "Your Tec-verse 2026 OTP for " + passType + " booking is " + otp + ".\n"
                + "This OTP is valid for 5 minutes.\n\n"
                + "Regards,\nTec-verse Team";
    }

    private static String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }

    private record OtpEntry(String otp, LocalDateTime expiresAt) {
    }
}
