package com.tecverse.app.exception;

public class OtpVerificationRequiredException extends RuntimeException {
    public OtpVerificationRequiredException(String message) {
        super(message);
    }
}
