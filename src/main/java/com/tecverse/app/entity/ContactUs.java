package com.tecverse.app.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate; 
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

/**
 * A message submitted through the public Contact Us / exhibitor-inquiry form.
 * Maps 1:1 to the pre-existing {@code contact_us} table.
 */
@Entity
@Table(
        name = "contact_us",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_contact_us_email", columnNames = "email"),
                @UniqueConstraint(name = "uk_contact_us_phone_number", columnNames = "phone_number")
        },
        indexes = @Index(name = "idx_contact_us_created_at", columnList = "created_at")
)
public class ContactUs {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "full_name", nullable = false, length = 150)
    private String fullName;

    @Column(name = "email", nullable = false, length = 255)
    private String email;

    @Column(name = "phone_number", length = 20)
    private String phoneNumber;

    @Column(name = "company_name", nullable = false, length = 200)
    private String companyName;

    @Column(name = "job_title", length = 150)
    private String jobTitle;

    @Column(name = "country", length = 100)
    private String country;

    @Column(name = "message", nullable = false, columnDefinition = "TEXT")
    private String message;

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

    public ContactUs() {
    }

    public ContactUs(Long id, String fullName, String email, String phoneNumber, String companyName,
                     String jobTitle, String country, String message, LocalDateTime createdAt,
                     LocalDateTime updatedAt) {
        this.id = id;
        this.fullName = fullName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.companyName = companyName;
        this.jobTitle = jobTitle;
        this.country = country;
        this.message = message;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static ContactUsBuilder builder() {
        return new ContactUsBuilder();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getJobTitle() {
        return jobTitle;
    }

    public void setJobTitle(String jobTitle) {
        this.jobTitle = jobTitle;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
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

    public static class ContactUsBuilder {
        private Long id;
        private String fullName;
        private String email;
        private String phoneNumber;
        private String companyName;
        private String jobTitle;
        private String country;
        private String message;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;

        public ContactUsBuilder id(Long id) {
            this.id = id;
            return this;
        }

        public ContactUsBuilder fullName(String fullName) {
            this.fullName = fullName;
            return this;
        }

        public ContactUsBuilder email(String email) {
            this.email = email;
            return this;
        }

        public ContactUsBuilder phoneNumber(String phoneNumber) {
            this.phoneNumber = phoneNumber;
            return this;
        }

        public ContactUsBuilder companyName(String companyName) {
            this.companyName = companyName;
            return this;
        }

        public ContactUsBuilder jobTitle(String jobTitle) {
            this.jobTitle = jobTitle;
            return this;
        }

        public ContactUsBuilder country(String country) {
            this.country = country;
            return this;
        }

        public ContactUsBuilder message(String message) {
            this.message = message;
            return this;
        }

        public ContactUsBuilder createdAt(LocalDateTime createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public ContactUsBuilder updatedAt(LocalDateTime updatedAt) {
            this.updatedAt = updatedAt;
            return this;
        }

        public ContactUs build() {
            return new ContactUs(id, fullName, email, phoneNumber, companyName,
                    jobTitle, country, message, createdAt, updatedAt);
        }
    }
}
