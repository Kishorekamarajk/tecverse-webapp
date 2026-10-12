package com.tecverse.app.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public class ConferenceScheduleItemForm {

    @Min(1)
    @Max(3)
    @NotNull(message = "Choose a schedule day.")
    private Integer dayNumber;

    @NotNull(message = "Choose a schedule date.")
    private LocalDate scheduleDate;

    @NotBlank(message = "Session title is required.")
    @Size(max = 220)
    private String sessionTitle;

    @NotBlank
    @Size(max = 20)
    @jakarta.validation.constraints.Pattern(regexp = "(?:[01]\\d|2[0-3]):[0-5]\\d", message = "Enter a valid start time in HH:mm format.")
    private String startTime;

    @NotBlank(message = "Choose an end time.")
    @Size(max = 20)
    @jakarta.validation.constraints.Pattern(regexp = "(?:[01]\\d|2[0-3]):[0-5]\\d", message = "Enter a valid end time in HH:mm format.")
    private String endTime;

    @PositiveOrZero(message = "Display order cannot be negative.")
    private int displayOrder = 0;

    private boolean highlighted = false;

    private boolean active = true;

    public Integer getDayNumber() {
        return dayNumber;
    }

    public void setDayNumber(Integer dayNumber) {
        this.dayNumber = dayNumber;
    }

    public LocalDate getScheduleDate() {
        return scheduleDate;
    }

    public void setScheduleDate(LocalDate scheduleDate) {
        this.scheduleDate = scheduleDate;
    }

    public String getSessionTitle() {
        return sessionTitle;
    }

    public void setSessionTitle(String sessionTitle) {
        this.sessionTitle = sessionTitle;
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

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }

    public boolean isHighlighted() {
        return highlighted;
    }

    public void setHighlighted(boolean highlighted) {
        this.highlighted = highlighted;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
