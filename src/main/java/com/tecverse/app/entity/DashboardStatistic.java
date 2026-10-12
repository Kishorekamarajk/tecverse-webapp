package com.tecverse.app.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "dashboard_statistics")
public class DashboardStatistic {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "participants", nullable = false)
    private long participants;

    @Column(name = "speakers", nullable = false)
    private long speakers;

    @Column(name = "organizations", nullable = false)
    private long organizations;

    @Column(name = "sessions", nullable = false)
    private long sessions;

    @Column(name = "partners", nullable = false)
    private long partners;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public DashboardStatistic() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public long getParticipants() {
        return participants;
    }

    public void setParticipants(long participants) {
        this.participants = participants;
    }

    public long getSpeakers() {
        return speakers;
    }

    public void setSpeakers(long speakers) {
        this.speakers = speakers;
    }

    public long getOrganizations() {
        return organizations;
    }

    public void setOrganizations(long organizations) {
        this.organizations = organizations;
    }

    public long getSessions() {
        return sessions;
    }

    public void setSessions(long sessions) {
        this.sessions = sessions;
    }

    public long getPartners() {
        return partners;
    }

    public void setPartners(long partners) {
        this.partners = partners;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
