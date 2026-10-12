package com.tecverse.app.entity;

import java.time.Instant;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "mobile_revoked_sessions")
public class MobileRevokedSession {
    @Id
    @Column(name = "token_fingerprint", nullable = false, length = 64)
    private String tokenFingerprint;
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
    protected MobileRevokedSession() { }
    public MobileRevokedSession(String fingerprint, Instant expiry) {
        tokenFingerprint = fingerprint;
        expiresAt = expiry;
    }
    public String getTokenFingerprint() { return tokenFingerprint; }
    public Instant getExpiresAt() { return expiresAt; }
}
