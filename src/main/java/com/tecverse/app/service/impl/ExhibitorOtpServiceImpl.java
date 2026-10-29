package com.tecverse.app.service.impl;

import com.tecverse.app.service.ExhibitorOtpService;
import com.tecverse.app.service.MailDeliveryService;
import com.tecverse.app.util.OtpConsoleLogger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

@Service
public class ExhibitorOtpServiceImpl implements ExhibitorOtpService {
    private static final int MAX_OTP_ATTEMPTS = 5;

    private record Entry(String otp, LocalDateTime expires, AtomicInteger failedAttempts) {}

    private final ConcurrentHashMap<String, Entry> codes = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, LocalDateTime> verified = new ConcurrentHashMap<>();
    private final SecureRandom random = new SecureRandom();
    private final MailDeliveryService mailDeliveryService;

    @Value("${tecverse.otp.log-to-console:false}")
    private boolean logOtpsToConsole;

    public ExhibitorOtpServiceImpl(MailDeliveryService mailDeliveryService) {
        this.mailDeliveryService = mailDeliveryService;
    }

    @Override
    public void send(String email, String name) {
        String normalized = norm(email);
        String otp = String.format("%06d", random.nextInt(1_000_000));
        codes.put(normalized, new Entry(otp, LocalDateTime.now().plusMinutes(5), new AtomicInteger()));
        verified.remove(normalized);

        String displayName = name == null || name.isBlank() ? "Exhibitor" : name.trim();
        String body = "Hello " + displayName + ",\n\n"
                + "Your Tec-Verse 2026 exhibitor verification OTP is " + otp + ".\n"
                + "This OTP is valid for 5 minutes.\n\n"
                + "Tec-Verse Team";

        try {
            boolean sent = mailDeliveryService.sendSimple(
                    normalized,
                    "Tec-Verse Exhibitor Email Verification OTP",
                    body,
                    "Exhibitor OTP"
            );
            if (!sent) throw new IllegalStateException("Unable to send exhibitor OTP email.");
            OtpConsoleLogger.printIfEnabled(logOtpsToConsole, "Exhibitor email verification", otp);
        } catch (IllegalStateException ex) {
            codes.remove(normalized);
            throw ex;
        }
    }

    @Override
    public void verify(String email, String otp) {
        String normalized = norm(email);
        Entry entry = codes.get(normalized);
        if (entry == null) throw new IllegalArgumentException("Please request a new OTP.");
        if (LocalDateTime.now().isAfter(entry.expires())) {
            codes.remove(normalized);
            throw new IllegalArgumentException("OTP has expired.");
        }
        if (otp == null || !MessageDigest.isEqual(entry.otp().getBytes(StandardCharsets.UTF_8),
                otp.trim().getBytes(StandardCharsets.UTF_8))) {
            if (entry.failedAttempts().incrementAndGet() >= MAX_OTP_ATTEMPTS) {
                codes.remove(normalized, entry);
                throw new IllegalArgumentException("Too many incorrect OTP attempts. Please request a new OTP.");
            }
            throw new IllegalArgumentException("Incorrect OTP.");
        }
        if (!codes.remove(normalized, entry)) throw new IllegalArgumentException("Please request a new OTP.");
        verified.put(normalized, LocalDateTime.now().plusMinutes(30));
    }

    @Override
    public boolean isVerified(String email) {
        LocalDateTime expires = verified.get(norm(email));
        return expires != null && LocalDateTime.now().isBefore(expires);
    }

    @Override
    public void consume(String email) {
        verified.remove(norm(email));
    }

    private String norm(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }
}
