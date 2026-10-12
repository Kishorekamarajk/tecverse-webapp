package com.tecverse.app.exception;

/** Thrown when a registration is submitted with an email address already on file. */
public class DuplicateEmailException extends RuntimeException {

    public DuplicateEmailException(String message) {
        super(message);
    }
}
