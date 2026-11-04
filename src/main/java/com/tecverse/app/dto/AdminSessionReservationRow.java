package com.tecverse.app.dto;

import java.time.LocalDateTime;

public record AdminSessionReservationRow(
        Long registrationId,
        Long reservationId,
        String attendeeName,
        String registrationReference,
        String sessionTitle,
        String sessionType,
        LocalDateTime reservedAt,
        LocalDateTime updatedAt,
        String status) {
}
