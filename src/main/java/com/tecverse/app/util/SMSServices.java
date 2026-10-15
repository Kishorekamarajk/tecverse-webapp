package com.tecverse.app.util;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Client for the C-DAC Mobile Seva SMS gateway (DLT OTP messages), matching the organisation's
 * licensed integration: same parameters, same password/key hashing, same success response.
 * A message is delivered only when its text matches the DLT template registered for {@code templateId}.
 */
public class SMSServices {

    /** Gateway reply prefix for an accepted message, e.g. {@code 402,MsgID = ...}. */
    public static final String SUCCESS_MARKER = "402,MsgID";

    private static final Logger log = LoggerFactory.getLogger(SMSServices.class);
    private static final HttpClient HTTP = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();

    private final String gatewayUrl;

    public SMSServices(String gatewayUrl) {
        this.gatewayUrl = gatewayUrl;
    }

    /** Sends a single OTP SMS and returns the raw gateway response (null if the gateway could not be reached). */
    public String sendOtpSMS(String username, String password, String message, String senderId,
                             String mobileNumber, String secureKey, String templateId) {
        String query = "username=" + enc(username)
                + "&password=" + enc(sha1Hex(password.trim()))
                + "&smsservicetype=" + enc("otpmsg")
                + "&content=" + enc(message.trim())
                + "&mobileno=" + enc(mobileNumber.trim())
                + "&senderid=" + enc(senderId)
                + "&key=" + enc(sha512Hex(username.trim() + senderId.trim() + message.trim() + secureKey.trim()))
                + "&templateid=" + enc(templateId);
        HttpRequest request = HttpRequest.newBuilder(URI.create(gatewayUrl))
                .timeout(Duration.ofSeconds(20))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(query))
                .build();
        try {
            return HTTP.send(request, HttpResponse.BodyHandlers.ofString()).body();
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            log.error("SMS gateway call interrupted");
            return null;
        } catch (Exception ex) {
            log.error("SMS gateway unreachable: {}", ex.getMessage());
            return null;
        }
    }

    private static String enc(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private static String sha1Hex(String text) {
        return hex("SHA-1", text.getBytes(StandardCharsets.ISO_8859_1));
    }

    private static String sha512Hex(String text) {
        return hex("SHA-512", text.getBytes(StandardCharsets.UTF_8));
    }

    private static String hex(String algorithm, byte[] input) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance(algorithm).digest(input));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(algorithm + " unavailable", ex);
        }
    }
}
