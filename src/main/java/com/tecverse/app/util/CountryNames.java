package com.tecverse.app.util;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;

public final class CountryNames {

    private static final List<String> ENGLISH_NAMES = Arrays.stream(Locale.getISOCountries())
            .map(countryCode -> new Locale.Builder().setRegion(countryCode).build()
                    .getDisplayCountry(Locale.ENGLISH))
            .filter(name -> !name.isBlank())
            .distinct()
            .sorted(String.CASE_INSENSITIVE_ORDER)
            .toList();

    private CountryNames() {
    }

    public static List<String> englishNames() {
        return ENGLISH_NAMES;
    }

    public static boolean containsEnglishName(String countryName) {
        return countryName != null && ENGLISH_NAMES.contains(countryName);
    }
}
