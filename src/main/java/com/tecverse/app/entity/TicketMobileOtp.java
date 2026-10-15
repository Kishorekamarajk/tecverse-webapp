package com.tecverse.app.entity;

import java.time.Instant;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Pending SMS OTP for /ticket mobile verification: one row per mobile number, deleted as soon as
 * the correct OTP is entered (or when it expires / runs out of attempts). Only a hash of the OTP is stored.
 */
@Entity
@Table(name = "tecverse_ticket_mobile_otps")
public class TicketMobileOtp {
    @Id
    @Column(name = "mobile", nullable = false, length = 10)
    private String mobile;
    @Column(name = "otp_hash", nullable = false, length = 64)
    private String otpHash;
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
    @Column(name = "failed_attempts", nullable = false)
    private int failedAttempts;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected TicketMobileOtp() { }

    public TicketMobileOtp(String mobile, String otpHash, Instant expiresAt) {
        this.mobile = mobile;
        this.otpHash = otpHash;
        this.expiresAt = expiresAt;
        this.createdAt = Instant.now();
    }

    public String getMobile() { return mobile; }
    public String getOtpHash() { return otpHash; }
    public Instant getExpiresAt() { return expiresAt; }
    public int getFailedAttempts() { return failedAttempts; }
    public int incrementFailedAttempts() { return ++failedAttempts; }
}
