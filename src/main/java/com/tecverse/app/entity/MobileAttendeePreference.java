package com.tecverse.app.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

/** Mobile-specific preferences keyed to the website attendee registration. */
@Entity
@Table(name = "mobile_attendee_preferences", uniqueConstraints =
        @UniqueConstraint(name = "uk_mobile_attendee_preferences_registration", columnNames = "registration_id"))
public class MobileAttendeePreference {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "registration_id", nullable = false, unique = true)
    private Long registrationId;
    @Column(name = "interests_json", nullable = false, columnDefinition = "TEXT")
    private String interestsJson = "[]";
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist @PreUpdate void touch() { updatedAt = LocalDateTime.now(); }
    public Long getRegistrationId() { return registrationId; }
    public String getInterestsJson() { return interestsJson; }
    public void setRegistrationId(Long value) { registrationId = value; }
    public void setInterestsJson(String value) { interestsJson = value; }
}
