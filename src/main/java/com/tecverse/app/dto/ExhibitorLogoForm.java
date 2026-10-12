package com.tecverse.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public class ExhibitorLogoForm {
    @NotBlank(message = "Company name is required.")
    @Size(max = 180, message = "Company name must be 180 characters or fewer.")
    private String companyName;
    @NotBlank(message = "Stall allocation is required.")
    @Size(max = 80, message = "Stall allocation must be 80 characters or fewer.")
    private String stallAllocation;
    @PositiveOrZero(message = "Display order cannot be negative.")
    private int displayOrder;
    private boolean active = true;

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }
    public String getStallAllocation() { return stallAllocation; }
    public void setStallAllocation(String stallAllocation) { this.stallAllocation = stallAllocation; }
    public int getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(int displayOrder) { this.displayOrder = displayOrder; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}
