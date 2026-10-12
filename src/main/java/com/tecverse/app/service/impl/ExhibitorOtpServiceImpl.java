package com.tecverse.app.service.impl;

import com.tecverse.app.service.ExhibitorOtpService;
import com.tecverse.app.service.MailDeliveryService;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ExhibitorOtpServiceImpl implements ExhibitorOtpService {
    private record Entry(String otp, LocalDateTime expires) {}

    private final ConcurrentHashMap<String, Entry> codes = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, LocalDateTime> verified = new ConcurrentHashMap<>();
    private final SecureRandom random = new SecureRandom();
    private final MailDeliveryService mailDeliveryService;

    public ExhibitorOtpServiceImpl(MailDeliveryService mailDeliveryService) {
        this.mailDeliveryService = mailDeliveryService;
    }

    @Override
    public void send(String email, String name) {
        String normalized = norm(email);
        String otp = String.format("%06d", random.nextInt(1_000_000));
        codes.put(normalized, new Entry(otp, LocalDateTime.now().plusMinutes(5)));
        verified.remove(normalized);

        String displayName = name == null || name.isBlank() ? "Exhibitor" : name.trim();
        String body = "Hello " + displayName + ",\n\n"
                + "Your Tec-verse 2026 exhibitor verification OTP is " + otp + ".\n"
                + "This OTP is valid for 5 minutes.\n\n"
                + "Tec-verse Team";

        try {
            mailDeliveryService.sendSimple(
                    normalized,
                    "Tec-verse Exhibitor Email Verification OTP",
                    body,
                    "Exhibitor OTP"
            );
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
        if (!entry.otp().equals(otp)) throw new IllegalArgumentException("Incorrect OTP.");
        codes.remove(normalized);
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
