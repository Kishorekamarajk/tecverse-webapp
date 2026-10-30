package com.tecverse.app.service;

import java.util.concurrent.CompletableFuture;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class TicketOtpEmailDeliveryService {

    private final MailDeliveryService mailDeliveryService;

    public TicketOtpEmailDeliveryService(MailDeliveryService mailDeliveryService) {
        this.mailDeliveryService = mailDeliveryService;
    }

    @Async("ticketOtpMailExecutor")
    public CompletableFuture<Void> send(String recipient, String subject, String body) {
        mailDeliveryService.sendSimple(recipient, subject, body, "Ticket OTP");
        return CompletableFuture.completedFuture(null);
    }
}
