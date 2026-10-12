package com.tecverse.app.entity;

import java.time.LocalDateTime;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "mobile_pass_check_ins", uniqueConstraints =
        @UniqueConstraint(name = "uk_mobile_pass_check_ins_registration", columnNames = "registration_id"))
public class MobilePassCheckIn {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "registration_id", nullable = false, unique = true)
    private Long registrationId;
    @Column(name = "gate_id", nullable = false, length = 80)
    private String gateId;
    @Column(name = "checked_in_at", nullable = false)
    private LocalDateTime checkedInAt;
    public Long getId() { return id; }
    public Long getRegistrationId() { return registrationId; }
    public String getGateId() { return gateId; }
    public LocalDateTime getCheckedInAt() { return checkedInAt; }
    public void setRegistrationId(Long value) { registrationId = value; }
    public void setGateId(String value) { gateId = value; }
    public void setCheckedInAt(LocalDateTime value) { checkedInAt = value; }
}
