package com.tecverse.app.security;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;

/** Creates and consumes the one-time, session-bound CAPTCHA used by admin login. */
@Component
public class AdminCaptchaService {
    private static final String SESSION_ATTRIBUTE = AdminCaptchaService.class.getName() + ".challenge";
    private static final char[] UPPERCASE = "ABCDEFGHJKLMNPQRSTUVWXYZ".toCharArray();
    private static final char[] LOWERCASE = "abcdefghijkmnopqrstuvwxyz".toCharArray();
    private static final char[] CHARACTERS = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789".toCharArray();
    private static final SecureRandom RANDOM = new SecureRandom();

    public String newChallenge(HttpSession session) {
        char[] challenge = new char[6];
        challenge[0] = UPPERCASE[RANDOM.nextInt(UPPERCASE.length)];
        challenge[1] = LOWERCASE[RANDOM.nextInt(LOWERCASE.length)];
        challenge[2] = "23456789".charAt(RANDOM.nextInt(8));
        for (int i = 3; i < challenge.length; i++) {
            challenge[i] = CHARACTERS[RANDOM.nextInt(CHARACTERS.length)];
        }
        for (int i = challenge.length - 1; i > 0; i--) {
            int j = RANDOM.nextInt(i + 1);
            char current = challenge[i];
            challenge[i] = challenge[j];
            challenge[j] = current;
        }
        String value = new String(challenge);
        session.setAttribute(SESSION_ATTRIBUTE, value);
        return value;
    }

    /** Consumes the challenge whether the submitted answer is correct or not. */
    public boolean consume(HttpSession session, String submitted) {
        Object stored = session.getAttribute(SESSION_ATTRIBUTE);
        session.removeAttribute(SESSION_ATTRIBUTE);
        if (!(stored instanceof String expected) || submitted == null) {
            return false;
        }
        byte[] expectedBytes = expected.getBytes(StandardCharsets.UTF_8);
        byte[] submittedBytes = submitted.trim().getBytes(StandardCharsets.UTF_8);
        return MessageDigest.isEqual(expectedBytes, submittedBytes);
    }
}
