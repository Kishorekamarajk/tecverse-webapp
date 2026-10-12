package com.tecverse.app.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.MobileAttendeePreference;

public interface MobileAttendeePreferenceRepository extends JpaRepository<MobileAttendeePreference, Long> {
    Optional<MobileAttendeePreference> findByRegistrationId(Long registrationId);
}
