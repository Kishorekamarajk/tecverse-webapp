package com.tecverse.app.service.impl;

import com.tecverse.app.service.MailDeliveryService;
import com.tecverse.app.service.SponsorOtpService;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

@Service
public class SponsorOtpServiceImpl implements SponsorOtpService {
    private static final int MAX_OTP_ATTEMPTS = 5;
    private static final SecureRandom RANDOM = new SecureRandom();

    private record Entry(String otp, LocalDateTime expiresAt, AtomicInteger failedAttempts) {}

    private final Map<String, Entry> codes = new ConcurrentHashMap<>();
    private final Map<String, LocalDateTime> verified = new ConcurrentHashMap<>();
    private final MailDeliveryService mailDeliveryService;

    public SponsorOtpServiceImpl(MailDeliveryService mailDeliveryService) {
        this.mailDeliveryService = mailDeliveryService;
    }

    @Override
    public void send(String email, String name) {
        String normalized = normalize(email);
        if (normalized.isBlank()) throw new IllegalArgumentException("Please enter a valid email address.");

        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));
        codes.put(normalized, new Entry(otp, LocalDateTime.now().plusMinutes(10), new AtomicInteger()));
        verified.remove(normalized);

        String displayName = name == null || name.isBlank() ? "Sponsor" : name.trim();
        String body = "Hello " + displayName + ",\n\n"
                + "Your Tec-Verse 2026 sponsor email verification OTP is: " + otp + "\n\n"
                + "This OTP is valid for 10 minutes. Do not share this OTP with anyone.\n\n"
                + "Tec-Verse Team";

        try {
            mailDeliveryService.sendSimple(
                    normalized,
                    "Tec-Verse 2026 Sponsor Email Verification OTP",
                    body,
                    "Sponsor OTP"
            );
        } catch (IllegalStateException ex) {
            codes.remove(normalized);
            throw ex;
        }
    }

    @Override
    public void verify(String email, String otp) {
        String normalized = normalize(email);
        Entry entry = codes.get(normalized);
        if (entry == null) throw new IllegalArgumentException("Please request a new OTP.");
        if (LocalDateTime.now().isAfter(entry.expiresAt())) {
            codes.remove(normalized);
            throw new IllegalArgumentException("OTP has expired. Please request a new OTP.");
        }
        if (otp == null || !MessageDigest.isEqual(entry.otp().getBytes(StandardCharsets.UTF_8),
                otp.trim().getBytes(StandardCharsets.UTF_8))) {
            if (entry.failedAttempts().incrementAndGet() >= MAX_OTP_ATTEMPTS) {
                codes.remove(normalized, entry);
                throw new IllegalArgumentException("Too many incorrect OTP attempts. Please request a new OTP.");
            }
            throw new IllegalArgumentException("Incorrect OTP. Please try again.");
        }
        if (!codes.remove(normalized, entry)) throw new IllegalArgumentException("Please request a new OTP.");
        verified.put(normalized, LocalDateTime.now().plusMinutes(30));
    }

    @Override
    public boolean isVerified(String email) {
        String normalized = normalize(email);
        LocalDateTime expiresAt = verified.get(normalized);
        if (expiresAt == null) return false;
        if (LocalDateTime.now().isAfter(expiresAt)) {
            verified.remove(normalized);
            return false;
        }
        return true;
    }

    @Override
    public void consume(String email) {
        verified.remove(normalize(email));
    }

    private String normalize(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }
}
