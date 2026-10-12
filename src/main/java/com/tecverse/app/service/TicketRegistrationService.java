package com.tecverse.app.service;
import com.tecverse.app.dto.TicketRegistrationRequest;
import com.tecverse.app.dto.TicketRegistrationResponse;
public interface TicketRegistrationService {
 TicketRegistrationResponse register(TicketRegistrationRequest request);
 void sendConfirmationForRegistration(Long registrationId);
}
