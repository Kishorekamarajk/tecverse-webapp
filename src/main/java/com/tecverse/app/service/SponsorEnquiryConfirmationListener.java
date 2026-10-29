package com.tecverse.app.service;

import com.tecverse.app.event.SponsorEnquirySavedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.context.event.EventListener;

@Component
public class SponsorEnquiryConfirmationListener {
    private static final Logger log = LoggerFactory.getLogger(SponsorEnquiryConfirmationListener.class);

    private final MailDeliveryService mailDeliveryService;

    public SponsorEnquiryConfirmationListener(MailDeliveryService mailDeliveryService) {
        this.mailDeliveryService = mailDeliveryService;
    }

    @Async
    @EventListener
    public void sendConfirmation(SponsorEnquirySavedEvent event) {
        String body = "Hello " + event.contactName() + ",\n\n"
                + "We have received your Tec-Verse 2026 sponsorship interest.\n"
                + "Organization: " + event.companyName() + "\n"
                + "Selected package: " + event.sponsorshipPackage() + "\n\n"
                + "Our team will contact you shortly regarding the next steps, package confirmation, invoice, and payment process.\n\n"
                + "Tec-Verse Team";
        try {
            mailDeliveryService.sendSimple(
                    event.email(),
                    "Tec-Verse 2026 Sponsorship Interest Received",
                    body,
                    "Sponsor confirmation"
            );
        } catch (IllegalStateException ex) {
            log.warn("Sponsor enquiry confirmation could not be sent to {}: {}", event.email(), ex.getMessage());
        }
    }
}
