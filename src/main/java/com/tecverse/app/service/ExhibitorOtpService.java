package com.tecverse.app.service;
public interface ExhibitorOtpService { void send(String email, String name); void verify(String email, String otp); boolean isVerified(String email); void consume(String email); }
