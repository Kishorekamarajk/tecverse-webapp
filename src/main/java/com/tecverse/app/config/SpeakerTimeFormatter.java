package com.tecverse.app.config;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.stereotype.Component;

@Component("speakerTimeFormatter")
public class SpeakerTimeFormatter {

    private static final Pattern TIME_PATTERN =
            Pattern.compile("(?i)(\\d{1,2}:\\d{2}\\s*(?:AM|PM)?)");
    private static final DateTimeFormatter TWELVE_HOUR_INPUT =
            DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH);
    private static final DateTimeFormatter TWENTY_FOUR_HOUR_INPUT =
            DateTimeFormatter.ofPattern("H:mm", Locale.ENGLISH);
    private static final DateTimeFormatter DISPLAY_FORMAT =
            DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH);

    public String format(String sessionTiming) {
        if (sessionTiming == null || sessionTiming.isBlank()) return sessionTiming;

        Matcher matcher = TIME_PATTERN.matcher(sessionTiming);
        StringBuffer formatted = new StringBuffer();
        while (matcher.find()) {
            String rawTime = matcher.group(1).trim().replaceAll("\\s+", " ").toUpperCase(Locale.ENGLISH);
            try {
                DateTimeFormatter inputFormat = rawTime.endsWith("AM") || rawTime.endsWith("PM")
                        ? TWELVE_HOUR_INPUT
                        : TWENTY_FOUR_HOUR_INPUT;
                String displayTime = LocalTime.parse(rawTime, inputFormat).format(DISPLAY_FORMAT);
                matcher.appendReplacement(formatted, Matcher.quoteReplacement(displayTime));
            } catch (DateTimeParseException ignored) {
                matcher.appendReplacement(formatted, Matcher.quoteReplacement(matcher.group(1)));
            }
        }
        matcher.appendTail(formatted);
        return formatted.toString();
    }
}
