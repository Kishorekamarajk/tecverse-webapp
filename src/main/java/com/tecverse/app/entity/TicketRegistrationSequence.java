package com.tecverse.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "tecverse_ticket_registration_sequences")
public class TicketRegistrationSequence {
    @Id
    @Column(name = "reference_code", length = 2, nullable = false)
    private String referenceCode;

    @Column(name = "last_value", nullable = false)
    private long lastValue;

    protected TicketRegistrationSequence() {}
}
