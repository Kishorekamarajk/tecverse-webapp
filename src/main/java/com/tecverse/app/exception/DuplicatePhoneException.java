package com.tecverse.app.exception;

/** Thrown when a registration is submitted with a phone number already on file. */
public class DuplicatePhoneException extends RuntimeException {

    public DuplicatePhoneException(String message) {
        super(message);
    }
}
