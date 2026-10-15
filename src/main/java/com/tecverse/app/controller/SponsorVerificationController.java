package com.tecverse.app.controller;

import com.tecverse.app.security.OtpSessionVerification;
import com.tecverse.app.security.OtpSessionVerification.Purpose;
import com.tecverse.app.service.SponsorOtpService;
import com.tecverse.app.service.RateLimitService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.time.Duration;

@RestController
@RequestMapping("/sponsor")
public class SponsorVerificationController {
    private final SponsorOtpService sponsorOtpService;
    private final RateLimitService rateLimitService;

    public SponsorVerificationController(SponsorOtpService sponsorOtpService, RateLimitService rateLimitService) {
        this.sponsorOtpService = sponsorOtpService;
        this.rateLimitService = rateLimitService;
    }

    @PostMapping("/send-otp")
    public ResponseEntity<Map<String, String>> sendOtp(@Valid @RequestBody OtpRequest request, HttpServletRequest httpRequest) {
        rateLimitService.check(httpRequest, "otp-send", request.email(), 3, Duration.ofMinutes(3), 30, Duration.ofMinutes(3));
        sponsorOtpService.send(request.email(), request.name());
        return ResponseEntity.ok(Map.of("message", "Verification OTP sent to your email."));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<Map<String, String>> verifyOtp(@Valid @RequestBody VerifyRequest request, HttpServletRequest httpRequest) {
        rateLimitService.check(httpRequest, "otp-verify", request.email(), 5, Duration.ofMinutes(3), 60, Duration.ofMinutes(3));
        sponsorOtpService.verify(request.email(), request.otp());
        OtpSessionVerification.markVerified(httpRequest, Purpose.SPONSOR, request.email());
        return ResponseEntity.ok(Map.of("message", "Email verified successfully."));
    }

    public record OtpRequest(
            @Email @NotBlank @Size(max = 254) String email,
            @Pattern(regexp = "^[A-Za-z][A-Za-z .'-]{1,149}$", message = "Enter a valid contact name.") String name) {}

    public record VerifyRequest(
            @Email @NotBlank @Size(max = 254) String email,
            @NotBlank @Pattern(regexp = "^\\d{6}$", message = "Enter the 6-digit OTP.") String otp) {}
}
