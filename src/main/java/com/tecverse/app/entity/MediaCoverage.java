package com.tecverse.app.entity;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

/**
 * An official Tec-verse social media post surfaced in the Media Coverage section.
 * Maps 1:1 to {@code media_coverage}.
 */
@Entity
@Table(
        name = "media_coverage",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_media_coverage_post_url", columnNames = "post_url"),
                @UniqueConstraint(name = "uk_media_coverage_platform_post_id", columnNames = {"platform", "post_id"})
        },
        indexes = {
                @Index(name = "idx_media_coverage_published_date", columnList = "published_date"),
                @Index(name = "idx_media_coverage_active_published_date", columnList = "active,published_date")
        }
)
public class MediaCoverage {

    private static final DateTimeFormatter CARD_DATE_FORMAT =
            DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH);
    private static final int CARD_DESCRIPTION_PREVIEW_LENGTH = 155;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", nullable = false, length = 20)
    private SocialPlatform platform;

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "post_id", length = 160)
    private String postId;

    @Column(name = "source_name", length = 160)
    private String sourceName;

    @Column(name = "media_type", length = 60)
    private String mediaType;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "post_url", nullable = false, length = 500)
    private String postUrl;

    @Column(name = "published_date", nullable = false)
    private LocalDateTime publishedDate;

    @Column(name = "active", nullable = false, columnDefinition = "boolean default true")
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

    public MediaCoverage() {
    }

    public MediaCoverage(Long id, SocialPlatform platform, String title, String postId, String sourceName,
                          String mediaType, String description, String imageUrl, String postUrl,
                          LocalDateTime publishedDate, boolean active, LocalDateTime createdAt,
                          LocalDateTime updatedAt) {
        this.id = id;
        this.platform = platform;
        this.title = title;
        this.postId = postId;
        this.sourceName = sourceName;
        this.mediaType = mediaType;
        this.description = description;
        this.imageUrl = imageUrl;
        this.postUrl = postUrl;
        this.publishedDate = publishedDate;
        this.active = active;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static MediaCoverageBuilder builder() {
        return new MediaCoverageBuilder();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public SocialPlatform getPlatform() {
        return platform;
    }

    public void setPlatform(SocialPlatform platform) {
        this.platform = platform;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getPostId() {
        return postId;
    }

    public void setPostId(String postId) {
        this.postId = postId;
    }

    public String getSourceName() {
        return sourceName;
    }

    public void setSourceName(String sourceName) {
        this.sourceName = sourceName;
    }

    public String getMediaType() {
        return mediaType;
    }

    public void setMediaType(String mediaType) {
        this.mediaType = mediaType;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getPostUrl() {
        return postUrl;
    }

    public void setPostUrl(String postUrl) {
        this.postUrl = postUrl;
    }

    public LocalDateTime getPublishedDate() {
        return publishedDate;
    }

    public void setPublishedDate(LocalDateTime publishedDate) {
        this.publishedDate = publishedDate;
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

    public String getPlatformDisplayName() {
        return platform == null ? "" : platform.getDisplayName();
    }

    public String getDescriptionPreview() {
        if (description == null || description.isBlank()) {
            return "View the original update from the official Tec-verse channel.";
        }
        String compact = description.replaceAll("\\s+", " ").trim();
        if (compact.length() <= CARD_DESCRIPTION_PREVIEW_LENGTH) {
            return compact;
        }
        return compact.substring(0, CARD_DESCRIPTION_PREVIEW_LENGTH).trim() + "...";
    }

    public String getPublishedDateLabel() {
        return publishedDate == null ? "" : CARD_DATE_FORMAT.format(publishedDate);
    }

    public String getActionLabel() {
        return platform == SocialPlatform.YOUTUBE ? "VIEW VIDEO" : "VIEW POST";
    }

    public static class MediaCoverageBuilder {
        private Long id;
        private SocialPlatform platform;
        private String title;
        private String postId;
        private String sourceName;
        private String mediaType;
        private String description;
        private String imageUrl;
        private String postUrl;
        private LocalDateTime publishedDate;
        private boolean active = true;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;

        public MediaCoverageBuilder id(Long id) { this.id = id; return this; }
        public MediaCoverageBuilder platform(SocialPlatform platform) { this.platform = platform; return this; }
        public MediaCoverageBuilder title(String title) { this.title = title; return this; }
        public MediaCoverageBuilder postId(String postId) { this.postId = postId; return this; }
        public MediaCoverageBuilder sourceName(String sourceName) { this.sourceName = sourceName; return this; }
        public MediaCoverageBuilder mediaType(String mediaType) { this.mediaType = mediaType; return this; }
        public MediaCoverageBuilder description(String description) { this.description = description; return this; }
        public MediaCoverageBuilder imageUrl(String imageUrl) { this.imageUrl = imageUrl; return this; }
        public MediaCoverageBuilder postUrl(String postUrl) { this.postUrl = postUrl; return this; }
        public MediaCoverageBuilder publishedDate(LocalDateTime publishedDate) { this.publishedDate = publishedDate; return this; }
        public MediaCoverageBuilder active(boolean active) { this.active = active; return this; }
        public MediaCoverageBuilder createdAt(LocalDateTime createdAt) { this.createdAt = createdAt; return this; }
        public MediaCoverageBuilder updatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public MediaCoverage build() {
            return new MediaCoverage(id, platform, title, postId, sourceName, mediaType, description, imageUrl,
                    postUrl, publishedDate, active, createdAt, updatedAt);
        }
    }
}
