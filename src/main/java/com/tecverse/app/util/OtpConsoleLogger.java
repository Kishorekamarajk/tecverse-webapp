package com.tecverse.app.util;

/** Prints OTP values to the application console only when explicitly enabled for local debugging. */
public final class OtpConsoleLogger {
    private OtpConsoleLogger() {}

    public static void printIfEnabled(boolean enabled, String purpose, String otp) {
        if (enabled) {
            System.out.printf("[DEV ONLY] %s OTP: %s%n", purpose, otp);
        }
    }
}
