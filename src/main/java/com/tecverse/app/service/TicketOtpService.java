package com.tecverse.app.service;
import com.tecverse.app.dto.TicketOtpSendRequest;
public interface TicketOtpService {
 String sendOtp(TicketOtpSendRequest request);
 String emailOtpDeliveryStatus(String requestId);
 void verifyOtp(String email,String otp);
 boolean isEmailVerified(String email);
 void sendMobileOtp(String phone);
 void sendExhibitorMobileOtp(String phone);
 void verifyMobileOtp(String phone,String otp);
}
