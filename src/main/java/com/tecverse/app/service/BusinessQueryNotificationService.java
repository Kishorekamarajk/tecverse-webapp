package com.tecverse.app.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class BusinessQueryNotificationService {
    private static final Logger log = LoggerFactory.getLogger(BusinessQueryNotificationService.class);
    private static final String SUPPORT_EMAIL = "stall-tecverse@cdac.in";
    private final MailDeliveryService mailDelivery;

    public BusinessQueryNotificationService(MailDeliveryService mailDelivery) {
        this.mailDelivery = mailDelivery;
    }

    @Async("ticketOtpMailExecutor")
    public void notifyStaff(String role, String name, String company, String phone, String query) {
        String body = "New " + role + " portal query\nName: " + name + "\nOrganization: " + company
                + "\nMobile: " + phone + "\n\nQuery:\n" + query.trim();
        try {
            mailDelivery.sendSimple(SUPPORT_EMAIL, "Tec-Verse " + role + " portal query", body,
                    "Business portal query");
        } catch (RuntimeException failure) {
            log.warn("Could not email staff about a saved business portal message", failure);
        }
    }
}
