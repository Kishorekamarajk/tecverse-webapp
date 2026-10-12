package com.tecverse.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public class ChiefGuestForm {

    @NotBlank
    @Size(max = 150)
    private String name;

    @NotBlank
    @Size(max = 180)
    private String designation;

    @NotBlank(message = "Organization is required.")
    @Size(max = 180, message = "Organization must be 180 characters or fewer.")
    private String organization;

    @NotBlank
    @Size(max = 20)
    @Pattern(regexp = "#[0-9A-Fa-f]{6}", message = "Use a six-digit hex color such as #00856F.")
    private String accentColor = "#00856F";

    @PositiveOrZero(message = "Display order cannot be negative.")
    private int displayOrder;

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

    public String getOrganization() {
        return organization;
    }

    public void setOrganization(String organization) {
        this.organization = organization;
    }

    public String getAccentColor() {
        return accentColor;
    }

    public void setAccentColor(String accentColor) {
        this.accentColor = accentColor;
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
