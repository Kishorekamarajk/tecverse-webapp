package com.tecverse.app.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import com.tecverse.app.entity.MobileNotification;

public interface MobileNotificationRepository extends JpaRepository<MobileNotification, Long> {
    List<MobileNotification> findTop100ByRegistrationIdOrderByCreatedAtDesc(Long registrationId);
    Optional<MobileNotification> findByIdAndRegistrationId(Long id, Long registrationId);
    int countByRegistrationIdAndReadFalse(Long registrationId);
    long deleteByRegistrationId(Long registrationId);
}
