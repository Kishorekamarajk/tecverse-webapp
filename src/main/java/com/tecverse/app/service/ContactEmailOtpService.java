package com.tecverse.app.service;

public interface ContactEmailOtpService {
    void send(String email, String name);
    void verify(String email, String otp);
}
