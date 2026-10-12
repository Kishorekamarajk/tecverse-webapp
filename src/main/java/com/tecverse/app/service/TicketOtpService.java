package com.tecverse.app.service;
import com.tecverse.app.dto.TicketOtpSendRequest;
public interface TicketOtpService {
 void sendOtp(TicketOtpSendRequest request);
 void verifyOtp(String email,String otp);
 boolean isEmailVerified(String email);
}
