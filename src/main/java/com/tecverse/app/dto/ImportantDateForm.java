package com.tecverse.app.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class ImportantDateForm {

    @NotBlank(message = "Title is required")
    @Size(max = 160, message = "Title must not exceed 160 characters")
    private String title;

    @NotNull(message = "Choose an event date.")
    private LocalDate eventDate;

    @NotBlank(message = "Icon class is required")
    @Size(max = 80, message = "Icon class must not exceed 80 characters")
    @Pattern(
            regexp = "bi-(calendar-event|calendar-check|calendar-date|calendar-week|calendar2-check|calendar3|clock|hourglass-split|pencil-square|megaphone|person-plus|people-fill|journal-check|cash-coin|credit-card|trophy|flag|geo-alt|ticket-perforated)",
            message = "Choose a Bootstrap icon from the list.")
    private String iconClass;

    @NotBlank(message = "Accent color is required")
    @Size(max = 20, message = "Accent color must not exceed 20 characters")
    @Pattern(regexp = "#[0-9A-Fa-f]{6}", message = "Use a six-digit hex color such as #00856F.")
    private String accentColor = "#00856F";

    @NotNull(message = "Display order is required")
    @PositiveOrZero(message = "Display order cannot be negative")
    private Integer displayOrder = 0;

    private boolean active = true;

    public ImportantDateForm() {
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public LocalDate getEventDate() {
        return eventDate;
    }

    public void setEventDate(LocalDate eventDate) {
        this.eventDate = eventDate;
    }

    public String getIconClass() {
        return iconClass;
    }

    public void setIconClass(String iconClass) {
        this.iconClass = iconClass;
    }

    public String getAccentColor() {
        return accentColor;
    }

    public void setAccentColor(String accentColor) {
        this.accentColor = accentColor;
    }

    public Integer getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(Integer displayOrder) {
        this.displayOrder = displayOrder;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
