package com.tecverse.app.service;

import com.tecverse.app.event.TicketRegistrationSavedEvent;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class TicketRegistrationConfirmationListener {
    private final TicketRegistrationService registrationService;

    public TicketRegistrationConfirmationListener(TicketRegistrationService registrationService) {
        this.registrationService = registrationService;
    }

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void sendConfirmation(TicketRegistrationSavedEvent event) {
        registrationService.sendConfirmationForRegistration(event.registrationId());
    }
}
