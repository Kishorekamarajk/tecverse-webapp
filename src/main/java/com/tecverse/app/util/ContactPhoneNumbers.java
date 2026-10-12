package com.tecverse.app.util;

import com.google.i18n.phonenumbers.NumberParseException;
import com.google.i18n.phonenumbers.PhoneNumberUtil;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

/** Country metadata and canonical international phone handling for inquiries. */
public final class ContactPhoneNumbers {
    private static final PhoneNumberUtil PHONES = PhoneNumberUtil.getInstance();
    private ContactPhoneNumbers() { }
    public record Country(String code, String name, String dialCode) { }

    public static List<Country> countries() {
        return PHONES.getSupportedRegions().stream()
                .map(code -> new Country(code, new Locale.Builder().setRegion(code).build()
                        .getDisplayCountry(Locale.ENGLISH), "+" + PHONES.getCountryCodeForRegion(code)))
                .sorted(Comparator.comparing(Country::name)).toList();
    }

    public static boolean supported(String country) {
        return country != null && PHONES.getSupportedRegions().contains(country);
    }

    public static String normalize(String value, String country) {
        if (!supported(country)) throw new IllegalArgumentException("Select a valid country.");
        if (value == null || value.isBlank()) return null;
        if (value.length() > 32 || !value.matches("\\+?[0-9 ()-]+")) {
            throw new IllegalArgumentException("Enter a valid phone number for the selected country.");
        }
        try {
            var number = PHONES.parse(value, country);
            if (!PHONES.isValidNumberForRegion(number, country) || number.hasExtension()) {
                throw new IllegalArgumentException("Enter a valid phone number for the selected country.");
            }
            return PHONES.format(number, PhoneNumberUtil.PhoneNumberFormat.E164);
        } catch (NumberParseException ex) {
            throw new IllegalArgumentException("Enter a valid phone number for the selected country.");
        }
    }

    public static String normalizeIndianMobile(String value) {
        String normalized = normalize(value, "IN");
        if (normalized == null || !normalized.matches("\\+91[6-9][0-9]{9}")) {
            throw new IllegalArgumentException("Enter a valid 10-digit Indian mobile number.");
        }
        return normalized;
    }
}
