package com.tecverse.app.dto.mobile;

public record MobileLoginRequest(String identifier, String email, String mobile, String password) {
    public String resolvedIdentifier() {
        if (identifier != null && !identifier.isBlank()) return identifier.trim();
        if (email != null && !email.isBlank()) return email.trim();
        return mobile == null ? "" : mobile.trim();
    }
}
