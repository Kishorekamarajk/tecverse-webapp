package com.tecverse.app.util;

/**
 * Normalizes and lightly sanitizes registration input before it reaches validation/persistence.
 *
 * <p>SQL-injection protection comes from Spring Data JPA/Hibernate, which always sends
 * parameterized queries - there is deliberately no quote/keyword blocklist here, since that
 * approach only breaks legitimate input (e.g. names like "O'Brien") without adding real security.
 *
 * <p>{@link #sanitize(String)} strips markup rather than HTML-entity-escaping it, so that
 * legitimate characters such as {@code &} are preserved unchanged in storage and in JSON
 * responses - escaping is Thymeleaf's job at render time, not the persistence layer's.
 */
public final class ValidationUtil {

    private static final java.util.regex.Pattern UNSAFE_MARKUP = java.util.regex.Pattern.compile(
            "(?is)<\\s*/?\\s*[a-z][^>]*(?:>|$)|javascript\\s*:|\\bon[a-z]+\\s*=|"
                    + "\\b(?:eval|alert|prompt|confirm)\\s*\\(|document\\.(?:write|cookie)\\b|"
                    + "(?:^|[;{}])\\s*(?:const|let|var|function|import|export)\\s+[A-Za-z_$]");

    private ValidationUtil() {
    }

    /** Trims whitespace and strips any HTML/script tags so markup can never be persisted verbatim. */
    public static String sanitize(String value) {
        if (value == null || value.isBlank()) {
            return value;
        }
        return value.trim().replaceAll("<[^>]*>", "");
    }

    /** True when user supplied text contains HTML tags or common executable markup. */
    public static boolean containsUnsafeMarkup(String value) {
        return value != null && UNSAFE_MARKUP.matcher(value).find();
    }

    /**
     * Strips spaces, hyphens and an optional leading +91 so "+91 98765-43210" and "9876543210"
     * are recognised as the same number for duplicate checks and storage.
     */
    public static String normalizeIndianMobile(String phone) {
        if (phone == null || phone.isBlank()) {
            return phone;
        }
        String digitsOnly = phone.replaceAll("[\\s-]", "");
        if (digitsOnly.startsWith("+91")) {
            digitsOnly = digitsOnly.substring(3);
        } else if (digitsOnly.startsWith("91") && digitsOnly.length() == 12) {
            digitsOnly = digitsOnly.substring(2);
        }
        return digitsOnly;
    }

    public static String normalizeGst(String gstNumber) {
        return (gstNumber == null || gstNumber.isBlank()) ? gstNumber : gstNumber.trim().toUpperCase();
    }
}
