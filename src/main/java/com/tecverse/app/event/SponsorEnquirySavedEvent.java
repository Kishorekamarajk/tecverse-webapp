package com.tecverse.app.event;

public record SponsorEnquirySavedEvent(
        String email,
        String contactName,
        String companyName,
        String sponsorshipPackage) {
}
