package com.tecverse.app.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import com.tecverse.app.entity.MobilePassCheckIn;

public interface MobilePassCheckInRepository extends JpaRepository<MobilePassCheckIn, Long> {
    Optional<MobilePassCheckIn> findByRegistrationId(Long registrationId);
    long deleteByRegistrationId(Long registrationId);
}
