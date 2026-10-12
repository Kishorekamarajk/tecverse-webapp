package com.tecverse.app.util;

/**
 * Regex patterns shared by the backend Bean Validation annotations and (conceptually) mirrored
 * by the client-side checks in exhibitor-registration.js, so both layers agree on what "valid" means.
 */
public final class Constants {

    private Constants() {
    }

    /** Indian mobile number, optionally prefixed with +91, starting with 6-9. */
    public static final String INDIAN_MOBILE_REGEX = "^(?:\\+91[-\\s]?)?[6-9]\\d{9}$";

    /** Standard 15-character Indian GSTIN. */
    public static final String GSTIN_REGEX = "^\\d{2}[A-Z]{5}\\d{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$";

    /** Letters, spaces, dots, apostrophes and hyphens only - covers common Indian name formats. */
    public static final String FULL_NAME_REGEX = "^[A-Za-z][A-Za-z .'-]{1,149}$";

    /** LinkedIn personal/company profile URL. Optional field - blank is also accepted. */
    public static final String LINKEDIN_REGEX = "^$|^https?://([a-zA-Z]{2,3}\\.)?linkedin\\.com/.*$";
}
