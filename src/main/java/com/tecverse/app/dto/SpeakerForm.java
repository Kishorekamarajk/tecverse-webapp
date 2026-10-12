package com.tecverse.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class SpeakerForm {

    @NotBlank(message = "Speaker name is required.")
    @Size(max = 160)
    private String name;

    @NotBlank(message = "Designation is required.")
    @Size(max = 180)
    private String designation;

    @NotBlank(message = "Choose a session start time.")
    @Size(max = 5)
    @Pattern(regexp = "(?:[01]\\d|2[0-3]):[0-5]\\d", message = "Choose a valid start time.")
    private String startTime;

    @NotBlank(message = "Choose a session end time.")
    @Size(max = 5)
    @Pattern(regexp = "(?:[01]\\d|2[0-3]):[0-5]\\d", message = "Choose a valid end time.")
    private String endTime;

    @NotBlank(message = "Choose the session date.")
    @Pattern(regexp = "\\d{4}-\\d{2}-\\d{2}", message = "Choose a valid session date.")
    private String sessionDate;

    @NotBlank(message = "Organization is required.")
    @Size(max = 180)
    private String organization;

    @PositiveOrZero(message = "Display order cannot be negative.")
    private int displayOrder = 0;

    private boolean active = true;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDesignation() {
        return designation;
    }

    public void setDesignation(String designation) {
        this.designation = designation;
    }

    public String getStartTime() {
        return startTime;
    }

    public void setStartTime(String startTime) {
        this.startTime = startTime;
    }

    public String getEndTime() {
        return endTime;
    }

    public void setEndTime(String endTime) {
        this.endTime = endTime;
    }

    public String getSessionDate() {
        return sessionDate;
    }

    public void setSessionDate(String sessionDate) {
        this.sessionDate = sessionDate;
    }

    public String getOrganization() {
        return organization;
    }

    public void setOrganization(String organization) {
        this.organization = organization;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
