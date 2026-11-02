package com.tecverse.app.service.impl;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import org.springframework.stereotype.Service;

import com.tecverse.app.service.ContactEmailOtpService;
import com.tecverse.app.service.MailDeliveryService;

@Service
public class ContactEmailOtpServiceImpl implements ContactEmailOtpService {
    private static final Duration VALIDITY = Duration.ofMinutes(5);
    private static final int MAX_ATTEMPTS = 5;
    private static final SecureRandom RANDOM = new SecureRandom();

    private record Entry(String otp, Instant expiresAt, AtomicInteger attempts) {}

    private final Map<String, Entry> entries = new ConcurrentHashMap<>();
    private final MailDeliveryService mailDeliveryService;

    public ContactEmailOtpServiceImpl(MailDeliveryService mailDeliveryService) {
        this.mailDeliveryService = mailDeliveryService;
    }

    @Override
    public void send(String email, String name) {
        String normalized = normalize(email);
        if (normalized.isBlank()) throw new IllegalArgumentException("Enter a valid email address.");
        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));
        Entry entry = new Entry(otp, Instant.now().plus(VALIDITY), new AtomicInteger());
        entries.put(normalized, entry);
        String recipient = name == null || name.isBlank() ? "there" : name.replaceAll("[\\r\\n]+", " ").trim();
        String body = "Hello " + recipient + ",\n\n"
                + "Your Tec-Verse 2026 Contact Us email verification code is " + otp + ".\n\n"
                + "This code is valid for 5 minutes. Please do not share it with anyone.\n\n"
                + "Tec-Verse 2026 Team";
        try {
            if (!mailDeliveryService.sendSimple(normalized, "Tec-Verse 2026 email verification", body,
                    "Contact enquiry email OTP")) {
                throw new IllegalStateException("Unable to send the verification email right now. Please try again later.");
            }
        } catch (RuntimeException ex) {
            entries.remove(normalized, entry);
            throw ex;
        }
    }

    @Override
    public void verify(String email, String otp) {
        String normalized = normalize(email);
        Entry entry = entries.get(normalized);
        if (entry == null) throw new IllegalArgumentException("Please request a new OTP.");
        if (Instant.now().isAfter(entry.expiresAt())) {
            entries.remove(normalized, entry);
            throw new IllegalArgumentException("OTP has expired. Please request a new OTP.");
        }
        if (otp == null || !MessageDigest.isEqual(entry.otp().getBytes(StandardCharsets.UTF_8),
                otp.trim().getBytes(StandardCharsets.UTF_8))) {
            if (entry.attempts().incrementAndGet() >= MAX_ATTEMPTS) {
                entries.remove(normalized, entry);
                throw new IllegalArgumentException("Too many incorrect OTP attempts. Please request a new OTP.");
            }
            throw new IllegalArgumentException("Incorrect OTP. Please try again.");
        }
        if (!entries.remove(normalized, entry)) throw new IllegalArgumentException("Please request a new OTP.");
    }

    private static String normalize(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }
}
