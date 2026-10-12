package com.tecverse.app.entity;

import java.time.LocalDateTime;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "mobile_notifications")
public class MobileNotification {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "registration_id", nullable = false)
    private Long registrationId;
    @Column(nullable = false, length = 180)
    private String title;
    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;
    @Column(nullable = false, length = 40)
    private String category = "ANNOUNCEMENT";
    @Column(nullable = false, length = 20)
    private String priority = "NORMAL";
    @Column(name = "action_route", length = 180)
    private String actionRoute;
    @Column(name = "is_read", nullable = false)
    private boolean read;
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    @PrePersist void create() { createdAt = LocalDateTime.now(); }
    public Long getId() { return id; }
    public Long getRegistrationId() { return registrationId; }
    public String getTitle() { return title; }
    public String getMessage() { return message; }
    public String getCategory() { return category; }
    public String getPriority() { return priority; }
    public String getActionRoute() { return actionRoute; }
    public boolean isRead() { return read; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setRegistrationId(Long value) { registrationId = value; }
    public void setTitle(String value) { title = value; }
    public void setMessage(String value) { message = value; }
    public void setCategory(String value) { category = value; }
    public void setPriority(String value) { priority = value; }
    public void setActionRoute(String value) { actionRoute = value; }
    public void setRead(boolean value) { read = value; }
}
