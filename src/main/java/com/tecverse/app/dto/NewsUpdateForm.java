package com.tecverse.app.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class NewsUpdateForm {

    @NotBlank(message = "News title is required.")
    @Size(max = 220, message = "News title must be 220 characters or fewer.")
    private String title;

    @NotNull(message = "Choose a publication date.")
    private LocalDate publishedDate;

    @NotBlank(message = "Short description is required.")
    @Size(max = 500, message = "Short description must be 500 characters or fewer.")
    private String excerpt;

    @NotBlank(message = "Full news content is required.")
    @Size(max = 10000, message = "Content must be 10,000 characters or less.")
    private String content;

    private boolean active = true;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public LocalDate getPublishedDate() {
        return publishedDate;
    }

    public void setPublishedDate(LocalDate publishedDate) {
        this.publishedDate = publishedDate;
    }

    public String getExcerpt() {
        return excerpt;
    }

    public void setExcerpt(String excerpt) {
        this.excerpt = excerpt;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
