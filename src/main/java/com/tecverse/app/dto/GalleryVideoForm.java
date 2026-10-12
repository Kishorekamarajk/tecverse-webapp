package com.tecverse.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class GalleryVideoForm {

    @NotBlank
    @Size(max = 180)
    private String title;

    @NotBlank
    @Size(max = 500)
    private String description;

    @Size(max = 500)
    @Pattern(regexp = "^(?:$|https?://\\S+|/(?!/)[^\\s]*)$", message = "Enter a valid video URL or local path.")
    private String videoUrl;

    @PositiveOrZero(message = "Display order cannot be negative.")
    private int displayOrder = 0;

    private boolean active = true;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getVideoUrl() {
        return videoUrl;
    }

    public void setVideoUrl(String videoUrl) {
        this.videoUrl = videoUrl;
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
