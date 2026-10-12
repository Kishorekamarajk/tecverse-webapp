package com.tecverse.app.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.GeneralSecurityException;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.tecverse.app.entity.TicketRegistration;
import com.tecverse.app.repository.TicketRegistrationRepository;
import com.tecverse.app.repository.MobileRevokedSessionRepository;
import com.tecverse.app.entity.MobileRevokedSession;
import com.tecverse.app.util.ValidationUtil;

/** Stateless signed bearer sessions backed by the shared website attendee records. */
@Service
public class MobileSessionService {
    private final TicketRegistrationRepository registrations;
    private final MobileRevokedSessionRepository revokedSessions;
    private final org.springframework.security.crypto.password.PasswordEncoder passwords;
    private final Duration lifetime;
    private final byte[] signingSecret;

    public MobileSessionService(TicketRegistrationRepository registrations, MobileRevokedSessionRepository revokedSessions,
            org.springframework.security.crypto.password.PasswordEncoder passwords,
            @Value("${tecverse.mobile.session-ttl:PT12H}") Duration lifetime,
            @Value("${tecverse.mobile.token-secret:}") String signingSecret) {
        this.registrations = registrations;
        this.revokedSessions = revokedSessions;
        this.passwords = passwords;
        this.lifetime = lifetime;
        this.signingSecret = signingSecret.getBytes(StandardCharsets.UTF_8);
    }

    public Map<String, Object> login(String identifier, String password) {
        if (identifier == null || identifier.isBlank() || password == null || password.isBlank()) {
            throw new IllegalArgumentException("Email or mobile and password are required.");
        }
        String clean = identifier.trim();
        var attendee = clean.contains("@")
                ? registrations.findByEmailIgnoreCase(clean)
                : registrations.findByPhone(ValidationUtil.normalizeIndianMobile(clean));
        TicketRegistration registration = attendee.orElseThrow(() -> new IllegalArgumentException("Invalid email/mobile or password."));
        String passwordHash = registration.getPasswordHash();
        if (passwordHash == null || passwordHash.isBlank() || !passwords.matches(password, passwordHash)) {
            throw new IllegalArgumentException("Invalid email/mobile or password.");
        }

        if (signingSecret.length < 32) {
            throw new IllegalStateException("Mobile sign-in is unavailable until MOBILE_TOKEN_SECRET is configured with at least 32 characters.");
        }
        long expiry = Instant.now().plus(lifetime).getEpochSecond();
        // Bind each session to the current password hash. Changing the password
        // invalidates every token issued before that change without a DB migration.
        String payload = registration.getId() + ":" + expiry + ":"
                + passwordFingerprint(registration.getPasswordHash()) + ":" + UUID.randomUUID();
        String encoded = Base64.getUrlEncoder().withoutPadding().encodeToString(payload.getBytes(StandardCharsets.UTF_8));
        String token = encoded + "." + signature(encoded);
        return Map.of("accessToken", token, "tokenType", "Bearer",
                "expiresIn", lifetime.toSeconds(), "user", profile(registration));
    }

    public TicketRegistration requireAttendee(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "A valid attendee session is required. Please sign in.");
        }
        String token = authorization.substring(7).trim();
        String[] parts = token.split("\\.", -1);
        if (parts.length != 2 || signingSecret.length < 32 || !MessageDigest.isEqual(
                signature(parts[0]).getBytes(StandardCharsets.US_ASCII), parts[1].getBytes(StandardCharsets.US_ASCII))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Attendee session is invalid. Please sign in again.");
        }
        if (revokedSessions.existsByTokenFingerprintAndExpiresAtAfter(fingerprint(token), Instant.now())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Attendee session has been signed out. Please sign in again.");
        }
        String[] claims;
        try {
            claims = new String(Base64.getUrlDecoder().decode(parts[0]), StandardCharsets.UTF_8).split(":", -1);
        } catch (IllegalArgumentException invalid) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Attendee session is invalid. Please sign in again.");
        }
        long attendeeId;
        long expiry;
        try {
            // Tokens from the previous two-claim format are deliberately rejected;
            // they cannot be invalidated when a password changes.
            if (claims.length != 4) throw new NumberFormatException("invalid claims");
            attendeeId = Long.parseLong(claims[0]);
            expiry = Long.parseLong(claims[1]);
        } catch (NumberFormatException invalid) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Attendee session is invalid. Please sign in again.");
        }
        if (expiry <= Instant.now().getEpochSecond()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Attendee session expired. Please sign in again.");
        }
        TicketRegistration attendee = registrations.findById(attendeeId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Attendee registration no longer exists."));
        if (attendee.getPasswordHash() == null || !MessageDigest.isEqual(
                passwordFingerprint(attendee.getPasswordHash()).getBytes(StandardCharsets.US_ASCII),
                claims[2].getBytes(StandardCharsets.US_ASCII))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Password changed. Please sign in again.");
        }
        return attendee;
    }

    public void logout(String authorization) {
        if (authorization != null && authorization.startsWith("Bearer ")) {
            String token = authorization.substring(7).trim();
            String[] parts = token.split("\\.", -1);
            if (parts.length == 2 && signingSecret.length >= 32 && MessageDigest.isEqual(
                    signature(parts[0]).getBytes(StandardCharsets.US_ASCII), parts[1].getBytes(StandardCharsets.US_ASCII))) {
                try {
                    String[] claims = new String(Base64.getUrlDecoder().decode(parts[0]), StandardCharsets.UTF_8).split(":", -1);
                    if (claims.length == 2 || claims.length == 4) {
                        revokedSessions.save(new MobileRevokedSession(fingerprint(token), Instant.ofEpochSecond(Long.parseLong(claims[1]))));
                    }
                } catch (RuntimeException ignored) {
                    // Invalid or expired tokens require no revocation record.
                }
            }
        }
    }

    public static Map<String, Object> profile(TicketRegistration attendee) {
        String organization = firstNonBlank(attendee.getCollegeName(), attendee.getUniversityName(),
                attendee.getOrganizationName(), attendee.getCentralMinistry(), attendee.getStateDepartment(), "TEC-VERSE Attendee");
        String designation = firstNonBlank(attendee.getDesignation(), attendee.getAcademiaRole(), "Delegate");
        return Map.ofEntries(
                Map.entry("id", attendee.getId()), Map.entry("referenceNumber", attendee.getReferenceNumber()),
                Map.entry("officialName", attendee.getOfficialName()), Map.entry("email", attendee.getEmail()),
                Map.entry("mobile", attendee.getPhone()), Map.entry("category", attendee.getCategory()),
                Map.entry("organization", organization), Map.entry("designation", designation),
                Map.entry("attendanceDays", attendee.getAttendanceDays()), Map.entry("interests", java.util.List.of()),
                Map.entry("registrationStatus", "registered"));
    }

    private static String firstNonBlank(String... values) {
        for (String value : values) if (value != null && !value.isBlank()) return value;
        return "";
    }

    private String signature(String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(signingSecret, "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(value.getBytes(StandardCharsets.US_ASCII)));
        } catch (GeneralSecurityException impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    private static String fingerprint(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (GeneralSecurityException impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    private static String passwordFingerprint(String passwordHash) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(passwordHash.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(digest);
        } catch (GeneralSecurityException impossible) {
            throw new IllegalStateException(impossible);
        }
    }
}
