package com.tecverse.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public class GalleryImageForm {

    @NotBlank(message = "Image title is required.")
    @Size(max = 180, message = "Title must be 180 characters or fewer.")
    private String title;

    @NotBlank(message = "Category / label is required.")
    @Size(max = 120, message = "Category / label must be 120 characters or fewer.")
    private String category;

    @PositiveOrZero(message = "Display order cannot be negative.")
    private int displayOrder = 0;

    private boolean active = true;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
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
