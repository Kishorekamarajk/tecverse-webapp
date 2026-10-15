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

    /** Organization, product or institution names: must contain a letter; may add digits, spaces and & . , ' ’ ( ) / # + -. Blank allowed. */
    public static final String ORG_NAME_REGEX = "^$|^(?=.*\\p{L})[\\p{L}\\p{M}\\p{N}][\\p{L}\\p{M}\\p{N} &.,'’()/#+-]*\\s*$";

    /** Designations and industry types: letters, spaces and & . , ' ’ ( ) / - (no digits). Blank allowed. */
    public static final String TITLE_REGEX = "^$|^[\\p{L}\\p{M}][\\p{L}\\p{M} &.,'’()/-]*\\s*$";

    /** City, state and country names: letters, spaces and . , ' ’ ( ) / - (no digits). Blank allowed. */
    public static final String PLACE_REGEX = "^$|^[\\p{L}\\p{M}][\\p{L}\\p{M} .,'’()/-]*\\s*$";

    /** Postal addresses: letters, digits, whitespace and , . / # ( ) & ' ’ : -. */
    public static final String ADDRESS_REGEX = "^[\\p{L}\\p{M}\\p{N}\\s,./#()&'’:-]*$";

    /** Free-text descriptions: anything except markup and code-like symbols. */
    public static final String FREE_TEXT_REGEX = "^[^<>{}\\[\\]\\\\`^|~$=*\"]*$";

    /** Equipment dimensions and weights, e.g. "2 × 1.5 m" or "350 kg". */
    public static final String MEASURE_REGEX = "^[\\p{L}\\p{N} ×.,()/-]*$";

    /** Company / CIN registration numbers. Blank allowed. */
    public static final String REGISTRATION_NUMBER_REGEX = "^$|^[A-Za-z0-9][A-Za-z0-9/-]*$";
}
