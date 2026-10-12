package com.tecverse.app.service;

import com.tecverse.app.exception.RateLimitExceededException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.Locale;
import java.util.ArrayDeque;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;

/** In-process sliding-window limits for public, state-changing requests. */
@Service
public class RateLimitService {
    private static final int MAX_TRACKED_KEYS = 50_000;
    private final Map<String, Bucket> buckets = new LinkedHashMap<>(256, 0.75f, true);
    private final Map<String, Cooldown> passwordResetCooldowns = new LinkedHashMap<>(256, 0.75f, true);

    /** Records reset-OTP sends and starts a cooldown after the configured number. */
    public synchronized long recordPasswordResetSend(String identity, int maxSends, Duration cooldown) {
        long now = System.currentTimeMillis();
        String key = "password-reset:" + digest(identity.trim().toLowerCase(Locale.ROOT));
        Cooldown state = passwordResetCooldowns.get(key);
        if (state != null && state.blockedUntilMillis() > now) {
            throw new RateLimitExceededException((state.blockedUntilMillis() - now + 999) / 1000);
        }
        if (state == null || state.blockedUntilMillis() > 0) {
            state = new Cooldown(0, 0);
        }
        int sends = state.sends() + 1;
        long blockedUntil = sends >= maxSends ? now + cooldown.toMillis() : 0;
        passwordResetCooldowns.put(key, new Cooldown(sends, blockedUntil));
        while (passwordResetCooldowns.size() > MAX_TRACKED_KEYS) {
            Iterator<String> oldest = passwordResetCooldowns.keySet().iterator();
            if (!oldest.hasNext()) break;
            oldest.next();
            oldest.remove();
        }
        return blockedUntil == 0 ? 0 : cooldown.toSeconds();
    }

    public synchronized void check(HttpServletRequest request, String action, String identity,
                                   int identityLimit, Duration identityWindow,
                                   int ipLimit, Duration ipWindow) {
        long now = System.currentTimeMillis();
        String ip = request.getRemoteAddr();
        String ipKey = "ip:" + action + ":" + digest(ip == null ? "unknown" : ip);
        String identityKey = identity == null || identity.isBlank()
                ? null : "identity:" + action + ":" + digest(identity.trim().toLowerCase(Locale.ROOT));

        Bucket ipBucket = bucket(ipKey);
        prune(ipBucket, now, ipWindow.toMillis());
        Bucket identityBucket = identityKey == null ? null : bucket(identityKey);
        if (identityBucket != null) prune(identityBucket, now, identityWindow.toMillis());

        long retryAfterMillis = retryAfter(ipBucket, now, ipWindow.toMillis(), ipLimit);
        if (identityBucket != null) {
            retryAfterMillis = Math.max(retryAfterMillis,
                    retryAfter(identityBucket, now, identityWindow.toMillis(), identityLimit));
        }
        if (retryAfterMillis > 0) {
            throw new RateLimitExceededException((retryAfterMillis + 999) / 1000);
        }

        ipBucket.requests().addLast(now);
        if (identityBucket != null) identityBucket.requests().addLast(now);
    }

    private Bucket bucket(String key) {
        Bucket bucket = buckets.computeIfAbsent(key, ignored -> new Bucket());
        while (buckets.size() > MAX_TRACKED_KEYS) {
            Iterator<String> oldest = buckets.keySet().iterator();
            if (!oldest.hasNext()) break;
            oldest.next();
            oldest.remove();
        }
        return bucket;
    }

    private static void prune(Bucket bucket, long now, long windowMillis) {
        long cutoff = now - windowMillis;
        while (!bucket.requests().isEmpty() && bucket.requests().peekFirst() <= cutoff) {
            bucket.requests().removeFirst();
        }
    }

    private static long retryAfter(Bucket bucket, long now, long windowMillis, int limit) {
        if (bucket.requests().size() < limit) return 0;
        return Math.max(1, bucket.requests().peekFirst() + windowMillis - now);
    }

    private static String digest(String value) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            char[] hex = new char[hash.length * 2];
            char[] digits = "0123456789abcdef".toCharArray();
            for (int i = 0; i < hash.length; i++) {
                int part = hash[i] & 0xff;
                hex[i * 2] = digits[part >>> 4];
                hex[i * 2 + 1] = digits[part & 0x0f];
            }
            return new String(hex);
        } catch (NoSuchAlgorithmException impossible) {
            throw new IllegalStateException("SHA-256 is unavailable", impossible);
        }
    }

    private static final class Bucket {
        private final ArrayDeque<Long> requests = new ArrayDeque<>();
        private ArrayDeque<Long> requests() { return requests; }
    }

    private record Cooldown(int sends, long blockedUntilMillis) {}
}
