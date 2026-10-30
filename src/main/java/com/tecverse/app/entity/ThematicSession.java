package com.tecverse.app.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "thematic_sessions", indexes = @Index(name = "idx_thematic_sessions_published", columnList = "published, active"))
public class ThematicSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(nullable = false, length = 180) private String title;
    @Column(length = 3000) private String description;
    @Column(name = "session_date", length = 40) private String sessionDate;
    @Column(name = "time_label", length = 100) private String timeLabel;
    @Column(name = "end_time_label", length = 100) private String endTimeLabel;
    @Column(name = "total_capacity", nullable = false) private int totalCapacity = 300;
    @Column(name = "reserved_seats", nullable = false) private int reservedSeats = 10;
    @Column(nullable = false) private boolean published;
    @Column(nullable = false) private boolean active = true;
    @Version private long version;
    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
    @PrePersist void create() { createdAt = LocalDateTime.now(); }
    public Long getId(){return id;} public String getTitle(){return title;} public String getDescription(){return description;}
    public String getSessionDate(){return sessionDate;} public String getTimeLabel(){return timeLabel;} public int getTotalCapacity(){return totalCapacity;}
    public String getEndTimeLabel(){return endTimeLabel;}
    public int getReservedSeats(){return reservedSeats;} public boolean isPublished(){return published;} public boolean isActive(){return active;}
    public void setTitle(String v){title=v;} public void setDescription(String v){description=v;} public void setSessionDate(String v){sessionDate=v;}
    public void setTimeLabel(String v){timeLabel=v;} public void setEndTimeLabel(String v){endTimeLabel=v;} public void setTotalCapacity(int v){totalCapacity=v;} public void setReservedSeats(int v){reservedSeats=v;}
    public void setPublished(boolean v){published=v;} public void setActive(boolean v){active=v;}
}
