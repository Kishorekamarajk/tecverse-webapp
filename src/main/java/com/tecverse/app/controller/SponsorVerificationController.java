package com.tecverse.app.controller;

import com.tecverse.app.service.SponsorOtpService;
import com.tecverse.app.service.TicketOtpService;
import com.tecverse.app.service.RateLimitService;
import com.tecverse.app.repository.SponsorEnquiryRepository;
import com.tecverse.app.security.OtpSessionVerification;
import com.tecverse.app.security.OtpSessionVerification.Purpose;
import com.tecverse.app.util.ValidationUtil;
import com.tecverse.app.exception.DuplicateEmailException;
import com.tecverse.app.exception.DuplicatePhoneException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.util.Map;

@RestController
@RequestMapping("/sponsor")
public class SponsorVerificationController {
    private final SponsorOtpService sponsorOtpService;
    private final RateLimitService rateLimitService;
    private final TicketOtpService ticketOtpService;
    private final SponsorEnquiryRepository sponsorEnquiryRepository;

    public SponsorVerificationController(SponsorOtpService sponsorOtpService, RateLimitService rateLimitService,
                                         TicketOtpService ticketOtpService, SponsorEnquiryRepository sponsorEnquiryRepository) {
        this.sponsorOtpService = sponsorOtpService;
        this.rateLimitService = rateLimitService;
        this.ticketOtpService = ticketOtpService;
        this.sponsorEnquiryRepository = sponsorEnquiryRepository;
    }

    @PostMapping("/send-otp")
    public ResponseEntity<Map<String, String>> sendOtp(@Valid @RequestBody OtpRequest request, HttpServletRequest httpRequest) {
        String email = request.email().trim().toLowerCase(java.util.Locale.ROOT);
        rateLimitService.check(httpRequest, "sponsor-email-otp-send", email, 3, Duration.ofMinutes(3), 30, Duration.ofMinutes(3));
        rateLimitService.check(httpRequest, "sponsor-email-otp-daily", email, 10, Duration.ofDays(1), 100, Duration.ofDays(1));
        if (sponsorEnquiryRepository.existsByEmailIgnoreCase(email)) {
            throw new DuplicateEmailException("This email is already registered as a sponsor.");
        }
        if (request.phone() != null && !request.phone().isBlank()) {
            String phone = requireIndianMobile(request.phone());
            if (sponsorEnquiryRepository.existsByPhone(phone)) {
                throw new DuplicatePhoneException("This mobile number is already registered as a sponsor.");
            }
        }
        rateLimitService.check(httpRequest, "sponsor-email-otp-resend-cooldown", email, 1, Duration.ofSeconds(60), 100, Duration.ofMinutes(1));
        sponsorOtpService.send(email, request.name().trim());
        return ResponseEntity.ok(Map.of("message", "Verification OTP sent to your email."));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<Map<String, String>> verifyOtp(@Valid @RequestBody VerifyRequest request, HttpServletRequest httpRequest) {
        rateLimitService.check(httpRequest, "otp-verify", request.email(), 5, Duration.ofMinutes(3), 60, Duration.ofMinutes(3));
        sponsorOtpService.verify(request.email(), request.otp());
        OtpSessionVerification.markVerified(httpRequest, Purpose.SPONSOR, request.email());
        return ResponseEntity.ok(Map.of("message", "Email verified successfully."));
    }

    @PostMapping("/send-mobile-otp")
    public ResponseEntity<Map<String, String>> sendMobileOtp(@RequestBody Map<String, String> body,
                                                             HttpServletRequest httpRequest) {
        String phone = requireIndianMobile(body.get("phone"));
        rateLimitService.check(httpRequest, "sponsor-sms-otp-send", phone, 3, Duration.ofMinutes(3), 20, Duration.ofMinutes(3));
        rateLimitService.check(httpRequest, "sponsor-sms-otp-daily", phone, 10, Duration.ofDays(1), 100, Duration.ofDays(1));
        if (sponsorEnquiryRepository.existsByPhone(phone)) {
            throw new DuplicatePhoneException("This mobile number is already registered as a sponsor.");
        }
        rateLimitService.check(httpRequest, "sponsor-sms-otp-resend-cooldown", phone, 1, Duration.ofSeconds(60), 100, Duration.ofMinutes(1));
        ticketOtpService.sendExhibitorMobileOtp(phone);
        return ResponseEntity.ok(Map.of("message", "OTP sent to your mobile number."));
    }

    @PostMapping("/verify-mobile-otp")
    public ResponseEntity<Map<String, String>> verifyMobileOtp(@RequestBody Map<String, String> body,
                                                               HttpServletRequest httpRequest) {
        String phone = requireIndianMobile(body.get("phone"));
        String otp = body.get("otp");
        if (otp == null || !otp.matches("^\\d{6}$")) throw new IllegalArgumentException("Enter the 6-digit OTP.");
        rateLimitService.check(httpRequest, "sponsor-sms-otp-verify", phone, 5, Duration.ofMinutes(1), 60, Duration.ofMinutes(1));
        ticketOtpService.verifyMobileOtp(phone, otp);
        OtpSessionVerification.markVerified(httpRequest, Purpose.SPONSOR_MOBILE, phone);
        return ResponseEntity.ok(Map.of("message", "Mobile number verified successfully."));
    }

    private static String requireIndianMobile(String value) {
        String phone = ValidationUtil.normalizeIndianMobile(value);
        if (phone == null || !phone.matches("^[6-9]\\d{9}$")) {
            throw new IllegalArgumentException("Enter a valid 10-digit Indian mobile number.");
        }
        return phone;
    }

    public record OtpRequest(
            @Email @NotBlank @Size(max = 254) String email,
            @NotBlank @Pattern(regexp = "^[A-Za-z][A-Za-z .'-]{1,149}$", message = "Enter a valid contact name.") String name,
            String phone) {}

    public record VerifyRequest(
            @Email @NotBlank @Size(max = 254) String email,
            @NotBlank @Pattern(regexp = "^\\d{6}$", message = "Enter the 6-digit OTP.") String otp) {}
}
