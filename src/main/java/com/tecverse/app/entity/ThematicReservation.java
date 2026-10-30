package com.tecverse.app.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name="thematic_reservations", uniqueConstraints=@UniqueConstraint(name="uk_thematic_reservation_user_session", columnNames={"registration_id","session_id"}), indexes=@Index(name="idx_thematic_reservation_session_status", columnList="session_id,status"))
public class ThematicReservation {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @Column(name="registration_id", nullable=false) private Long registrationId;
    @Column(name="session_id", nullable=false) private Long sessionId;
    @Column(nullable=false, length=20) private String status="CONFIRMED";
    @Column(name="created_at", nullable=false) private LocalDateTime createdAt;
    @Column(name="updated_at", nullable=false) private LocalDateTime updatedAt;
    @PrePersist void create(){createdAt=updatedAt=LocalDateTime.now();}
    @PreUpdate void update(){updatedAt=LocalDateTime.now();}
    public Long getId(){return id;} public Long getRegistrationId(){return registrationId;} public Long getSessionId(){return sessionId;} public String getStatus(){return status;}
    public void setRegistrationId(Long v){registrationId=v;} public void setSessionId(Long v){sessionId=v;} public void setStatus(String v){status=v;}
}
