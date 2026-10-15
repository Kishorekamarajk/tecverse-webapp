-- Pending SMS OTPs for /ticket mobile number verification (PostgreSQL).
-- Run once on each database before deploying (spring.jpa.hibernate.ddl-auto=validate will not create it).
-- A row is deleted as soon as the correct OTP is entered; expired rows are purged hourly by the app.
CREATE TABLE IF NOT EXISTS tecverse_ticket_mobile_otps (
    mobile          VARCHAR(10)  PRIMARY KEY,
    otp_hash        VARCHAR(64)  NOT NULL,
    expires_at      TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    failed_attempts INTEGER      NOT NULL DEFAULT 0,
    created_at      TIMESTAMP(6) WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ticket_mobile_otps_expires_at ON tecverse_ticket_mobile_otps (expires_at);
