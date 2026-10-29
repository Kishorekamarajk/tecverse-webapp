package com.tecverse.app.service;

import com.tecverse.app.event.ExhibitorRegistrationSavedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class ExhibitorRegistrationConfirmationListener {
    private static final Logger log = LoggerFactory.getLogger(ExhibitorRegistrationConfirmationListener.class);
    private final MailDeliveryService mailDeliveryService;

    public ExhibitorRegistrationConfirmationListener(MailDeliveryService mailDeliveryService) {
        this.mailDeliveryService = mailDeliveryService;
    }

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void sendConfirmation(ExhibitorRegistrationSavedEvent event) {
        String body = "Hello " + event.fullName() + ",\n\n"
                + "Your exhibitor application has been received successfully.\n"
                + "Reference Number: " + event.referenceNumber() + "\n"
                + "Company: " + event.companyName() + "\n"
                + "Stall Package: " + event.stallPackage() + "\n\n"
                + "Our team will review your application and contact you regarding the next steps.\n\n"
                + "Tec-Verse Team";
        try {
            mailDeliveryService.sendSimple(
                    event.email(),
                    "Tec-Verse 2026 Exhibitor Registration - " + event.referenceNumber(),
                    body,
                    "Exhibitor confirmation"
            );
        } catch (IllegalStateException ex) {
            log.warn("Exhibitor registration {} is saved, but its confirmation email could not be sent: {}",
                    event.referenceNumber(), ex.getMessage());
        }
    }
}
