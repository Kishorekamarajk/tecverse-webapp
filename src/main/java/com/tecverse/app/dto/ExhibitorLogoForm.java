package com.tecverse.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class ExhibitorLogoForm {
    @NotBlank(message = "Company name is required.")
    @Size(max = 180, message = "Company name must be 180 characters or fewer.")
    private String companyName;
    @NotBlank(message = "Stall allocation is required.")
    @Size(max = 80, message = "Stall allocation must be 80 characters or fewer.")
    private String stallAllocation;
    @Size(max = 500, message = "Website URL must be 500 characters or fewer.")
    @Pattern(regexp = "(?i)^(https?://[^\\s]+)?$", message = "Enter a valid URL starting with http:// or https://.")
    private String websiteUrl;
    @PositiveOrZero(message = "Display order cannot be negative.")
    private int displayOrder;
    private boolean active = true;

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }
    public String getStallAllocation() { return stallAllocation; }
    public void setStallAllocation(String stallAllocation) { this.stallAllocation = stallAllocation; }
    public String getWebsiteUrl() { return websiteUrl; }
    public void setWebsiteUrl(String websiteUrl) { this.websiteUrl = websiteUrl == null ? null : websiteUrl.trim(); }
    public int getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(int displayOrder) { this.displayOrder = displayOrder; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}
