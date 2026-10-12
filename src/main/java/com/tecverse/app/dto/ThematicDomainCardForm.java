package com.tecverse.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public class ThematicDomainCardForm {

    @NotBlank(message = "Choose an institution.")
    @Pattern(regexp = "cdac|sameer|cmet", message = "Choose C-DAC, SAMEER, or C-MET.")
    private String institution = "cdac";

    @NotBlank(message = "Card title is required.")
    @Size(max = 180, message = "Card title must be 180 characters or fewer.")
    private String title;

    @NotBlank(message = "Bootstrap icon name is required.")
    @Size(max = 80, message = "Icon name must be 80 characters or fewer.")
    @Pattern(
            regexp = "stars|cpu-fill|robot|cpu|shield-lock|code-slash|flag|link-45deg|reception-4|shield-check|cloud-sun|heart-pulse-fill|broadcast|gear-wide-connected|memory|lightning-charge|box-seam|battery-charging|recycle|layers",
            message = "Choose a Bootstrap icon from the list.")
    private String icon = "stars";

    @NotBlank(message = "Card description is required.")
    @Size(max = 600, message = "Description must be 600 characters or fewer.")
    private String description;

    @PositiveOrZero(message = "Display order cannot be negative.")
    @NotNull(message = "Display order is required.")
    private Integer displayOrder = 0;

    private boolean active = true;

    public String getInstitution() {
        return institution;
    }

    public void setInstitution(String institution) {
        this.institution = institution;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
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
