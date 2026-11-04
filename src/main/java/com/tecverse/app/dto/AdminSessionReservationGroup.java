package com.tecverse.app.dto;

import java.util.List;

public record AdminSessionReservationGroup(
        Long registrationId,
        String attendeeName,
        String registrationReference,
        List<AdminSessionReservationRow> reservations) {
}
