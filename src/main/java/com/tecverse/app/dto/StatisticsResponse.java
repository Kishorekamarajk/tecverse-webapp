package com.tecverse.app.dto;

public record StatisticsResponse(
        long participants,
        long speakers,
        long collaborators,
        long sessions,
        long partners
) {
}
