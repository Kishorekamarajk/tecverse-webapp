package com.tecverse.app.repository;

import java.time.Instant;
import org.springframework.data.jpa.repository.JpaRepository;
import com.tecverse.app.entity.MobileRevokedSession;

public interface MobileRevokedSessionRepository extends JpaRepository<MobileRevokedSession, String> {
    boolean existsByTokenFingerprintAndExpiresAtAfter(String fingerprint, Instant now);
}
