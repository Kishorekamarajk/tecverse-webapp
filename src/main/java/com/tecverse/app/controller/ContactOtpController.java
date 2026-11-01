package com.tecverse.app.controller;

import java.time.Duration;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.tecverse.app.response.ApiResponse;
import com.tecverse.app.security.OtpSessionVerification;
import com.tecverse.app.security.OtpSessionVerification.Purpose;
import com.tecverse.app.service.RateLimitService;
import com.tecverse.app.service.TicketOtpService;
import com.tecverse.app.service.ContactEmailOtpService;
import com.tecverse.app.repository.ContactUsRepository;
import com.tecverse.app.util.ContactPhoneNumbers;

import jakarta.servlet.http.HttpServletRequest;

@RestController
public class ContactOtpController {
    private final TicketOtpService ticketOtpService;
    private final ContactEmailOtpService contactEmailOtpService;
    private final RateLimitService rateLimitService;
    private final ContactUsRepository contactUsRepository;

    public ContactOtpController(TicketOtpService ticketOtpService, ContactEmailOtpService contactEmailOtpService,
                                RateLimitService rateLimitService, ContactUsRepository contactUsRepository) {
        this.ticketOtpService = ticketOtpService;
        this.contactEmailOtpService = contactEmailOtpService;
        this.rateLimitService = rateLimitService;
        this.contactUsRepository = contactUsRepository;
    }

    @PostMapping(value = "/contact/send-email-otp", consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> sendEmailOtp(@RequestBody Map<String, String> body,
                                                           HttpServletRequest request) {
        String email = normalizeEmail(body.get("email"));
        String name = body.get("name");
        rateLimitService.check(request, "contact-email-otp-send", email, 3, Duration.ofMinutes(3), 30, Duration.ofMinutes(3));
        rateLimitService.check(request, "contact-email-otp-daily", email, 10, Duration.ofDays(1), 100, Duration.ofDays(1));
        rateLimitService.check(request, "contact-email-otp-resend", email, 1, Duration.ofSeconds(60), 100, Duration.ofMinutes(1));
        if (contactUsRepository.existsByEmailIgnoreCase(email)) {
            throw new IllegalArgumentException("This email address has already been used for an enquiry. Please use another email address.");
        }
        contactEmailOtpService.send(email, name);
        OtpSessionVerification.consume(request, Purpose.CONTACT_EMAIL);
        return ResponseEntity.ok(ApiResponse.success("Verification code sent to your email address."));
    }

    @PostMapping(value = "/contact/verify-email-otp", consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> verifyEmailOtp(@RequestBody Map<String, String> body,
                                                             HttpServletRequest request) {
        String email = normalizeEmail(body.get("email"));
        String otp = body.get("otp");
        if (otp == null || !otp.matches("^\\d{6}$")) {
            throw new IllegalArgumentException("Enter the 6-digit OTP.");
        }
        rateLimitService.check(request, "contact-email-otp-verify", email, 5, Duration.ofMinutes(1), 60, Duration.ofMinutes(1));
        contactEmailOtpService.verify(email, otp);
        OtpSessionVerification.markVerified(request, Purpose.CONTACT_EMAIL, email);
        return ResponseEntity.ok(ApiResponse.success("Email address verified successfully."));
    }

    @PostMapping(value = "/contact/send-mobile-otp", consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> sendMobileOtp(@RequestBody Map<String, String> body,
                                                             HttpServletRequest request) {
        String phone = normalizeIndianNumber(body.get("phone"));
        rateLimitService.check(request, "contact-sms-otp-send", phone, 3, Duration.ofMinutes(3), 20, Duration.ofMinutes(3));
        rateLimitService.check(request, "contact-sms-otp-daily", phone, 10, Duration.ofDays(1), 100, Duration.ofDays(1));
        rateLimitService.check(request, "contact-sms-otp-resend", phone, 1, Duration.ofSeconds(60), 100, Duration.ofMinutes(1));
        if (contactUsRepository.existsByPhoneNumber(phone)) {
            throw new IllegalArgumentException("This mobile number has already been used for an enquiry. Please use another number.");
        }
        ticketOtpService.sendContactMobileOtp(phone);
        OtpSessionVerification.consume(request, Purpose.CONTACT_MOBILE);
        return ResponseEntity.ok(ApiResponse.success("OTP sent to your mobile number."));
    }

    @PostMapping(value = "/contact/verify-mobile-otp", consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> verifyMobileOtp(@RequestBody Map<String, String> body,
                                                              HttpServletRequest request) {
        String phone = normalizeIndianNumber(body.get("phone"));
        String otp = body.get("otp");
        if (otp == null || !otp.matches("^\\d{6}$")) {
            throw new IllegalArgumentException("Enter the 6-digit OTP.");
        }
        rateLimitService.check(request, "contact-sms-otp-verify", phone, 5, Duration.ofMinutes(1), 60, Duration.ofMinutes(1));
        ticketOtpService.verifyContactMobileOtp(phone, otp);
        OtpSessionVerification.markVerified(request, Purpose.CONTACT_MOBILE, phone);
        return ResponseEntity.ok(ApiResponse.success("Mobile number verified successfully."));
    }

    private static String normalizeIndianNumber(String phone) {
        String normalized = ContactPhoneNumbers.normalize(phone, "IN");
        if (normalized == null || !normalized.matches("\\+91[6-9][0-9]{9}")) {
            throw new IllegalArgumentException("Enter a valid 10-digit Indian mobile number.");
        }
        return normalized;
    }

    private static String normalizeEmail(String value) {
        String email = value == null ? "" : value.trim().toLowerCase(java.util.Locale.ROOT);
        if (email.length() > 254 || !email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
            throw new IllegalArgumentException("Enter a valid email address.");
        }
        return email;
    }
}
