package com.tecverse.app.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
        name = "news_updates",
        uniqueConstraints = @UniqueConstraint(name = "uk_news_updates_slug", columnNames = "slug")
)
public class NewsUpdate {

    private static final DateTimeFormatter CARD_DATE_FORMAT =
            DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH);
    private static final int EXCERPT_LIMIT = 150;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "slug", nullable = false, length = 180)
    private String slug;

    @Column(name = "title", nullable = false, length = 220)
    private String title;

    @Column(name = "published_date", nullable = false)
    private LocalDate publishedDate;

    @Column(name = "image_url", nullable = false, length = 500)
    private String imageUrl;

    @Column(name = "excerpt", nullable = false, length = 500)
    private String excerpt;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getSlug() {
        return slug;
    }

    public void setSlug(String slug) {
        this.slug = slug;
    }

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

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
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

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public String getDateLabel() {
        return publishedDate == null ? "" : CARD_DATE_FORMAT.format(publishedDate);
    }

    public String getDisplayExcerpt() {
        if (excerpt != null && !excerpt.isBlank()) {
            return excerpt.trim();
        }
        String compact = content == null ? "" : content.replaceAll("\\s+", " ").trim();
        if (compact.length() <= EXCERPT_LIMIT) {
            return compact;
        }
        return compact.substring(0, EXCERPT_LIMIT).trim() + "...";
    }

    public List<String> getParagraphs() {
        String source = content == null || content.isBlank() ? getDisplayExcerpt() : content;
        return List.of(source.split("\\R\\s*\\R|\\R")).stream()
                .map(String::trim)
                .filter(paragraph -> !paragraph.isBlank())
                .toList();
    }
}
