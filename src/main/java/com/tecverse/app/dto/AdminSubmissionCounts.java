package com.tecverse.app.dto;

public record AdminSubmissionCounts(
        long ticketRegistrations,
        long exhibitors,
        long sponsors,
        long contactUs
) {
}
