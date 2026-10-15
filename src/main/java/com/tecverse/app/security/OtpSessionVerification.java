package com.tecverse.app.security;

import java.io.Serializable;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;

import com.tecverse.app.exception.OtpVerificationRequiredException;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

/**
 * Server-side record of a successful OTP verification, bound to the visitor's HTTP session.
 * The browser never holds a verification flag it can forge: a final submission is accepted
 * only when this session itself completed OTP verification for the same email address.
 */
public final class OtpSessionVerification {

    /** TICKET_MOBILE records the verified mobile number (stored in place of the email). */
    public enum Purpose { TICKET, TICKET_MOBILE, EXHIBITOR, SPONSOR }

    private static final Duration VALIDITY = Duration.ofMinutes(30);

    private record Verified(String email, Instant expiresAt) implements Serializable {}

    private OtpSessionVerification() {
    }

    public static void markVerified(HttpServletRequest request, Purpose purpose, String email) {
        request.getSession(true);
        // Rotate the session id at the privilege change to rule out session fixation.
        request.changeSessionId();
        request.getSession().setAttribute(key(purpose), new Verified(normalize(email), Instant.now().plus(VALIDITY)));
    }

    public static boolean isVerified(HttpServletRequest request, Purpose purpose, String email) {
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        if (!(session.getAttribute(key(purpose)) instanceof Verified verified)) return false;
        if (Instant.now().isAfter(verified.expiresAt())) {
            session.removeAttribute(key(purpose));
            return false;
        }
        return verified.email().equals(normalize(email));
    }

    /** True when this session holds a current (unexpired) verification for any email address. */
    public static boolean hasVerification(HttpServletRequest request, Purpose purpose) {
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        if (!(session.getAttribute(key(purpose)) instanceof Verified verified)) return false;
        if (Instant.now().isAfter(verified.expiresAt())) {
            session.removeAttribute(key(purpose));
            return false;
        }
        return true;
    }

    public static void require(HttpServletRequest request, Purpose purpose, String email) {
        if (!isVerified(request, purpose, email)) {
            throw new OtpVerificationRequiredException("Please verify your email with OTP before submitting.");
        }
    }

    public static void consume(HttpServletRequest request, Purpose purpose) {
        HttpSession session = request.getSession(false);
        if (session != null) session.removeAttribute(key(purpose));
    }

    private static String key(Purpose purpose) {
        return "otp.verified." + purpose.name();
    }

    private static String normalize(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }
}
