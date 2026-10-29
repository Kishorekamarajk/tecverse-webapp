package com.tecverse.app.event;

public record ExhibitorRegistrationSavedEvent(
        String email,
        String fullName,
        String referenceNumber,
        String companyName,
        String stallPackage) {}
