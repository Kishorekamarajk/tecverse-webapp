package com.tecverse.app.dto;

public record AdminSessionParticipantSummary(
        Long registrationId,
        String attendeeName,
        String registrationReference) {
}
