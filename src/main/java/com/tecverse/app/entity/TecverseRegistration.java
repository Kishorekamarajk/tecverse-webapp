package com.tecverse.app.entity;

import java.time.LocalDateTime;

import org.hibernate.validator.constraints.URL;

import com.tecverse.app.validator.Gstin;
import com.tecverse.app.validator.IndianMobile;

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
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * An exhibitor's registration for TecVerse. Maps 1:1 to {@code tecverse_registrations}.
 */
@Entity
@Table(
        name = "tecverse_registrations",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_tecverse_registrations_email", columnNames = "email"),
                @UniqueConstraint(name = "uk_tecverse_registrations_phone", columnNames = "phone")
        },
        indexes = {
                @Index(name = "idx_tecverse_registrations_created_at", columnList = "created_at"),
                @Index(name = "idx_tecverse_registrations_company_name", columnList = "company_name")
        }
)
public class TecverseRegistration {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ---------------- Company Information ----------------

    @NotBlank
    @Size(min = 3, max = 200)
    @Column(name = "company_name", nullable = false, length = 200)
    private String companyName;

    @URL
    @Size(max = 255)
    @Column(name = "website", length = 255)
    private String website;

    @NotBlank
    @Size(max = 100)
    @Column(name = "industry", nullable = false, length = 100)
    private String industry;

    @NotBlank
    @Size(max = 100)
    @Column(name = "city", nullable = false, length = 100)
    private String city;

    @NotBlank
    @Size(max = 100)
    @Column(name = "country", nullable = false, length = 100)
    private String country;

    @Gstin
    @Column(name = "gst_number", length = 15)
    private String gstNumber;

    @NotBlank
    @Size(max = 50)
    @Column(name = "company_size", nullable = false, length = 50)
    private String companySize;

    // ---------------- Contact Information ----------------

    @NotBlank
    @Size(max = 150)
    @Column(name = "full_name", nullable = false, length = 150)
    private String fullName;

    @NotBlank
    @Email
    @Size(max = 150)
    @Column(name = "email", nullable = false, length = 150)
    private String email;

    @NotBlank
    @IndianMobile
    @Column(name = "phone", nullable = false, length = 20)
    private String phone;

    @NotBlank
    @Size(max = 100)
    @Column(name = "designation", nullable = false, length = 100)
    private String designation;

    @URL
    @Size(max = 255)
    @Column(name = "linkedin_profile", length = 255)
    private String linkedinProfile;

    // ---------------- Exhibition Details ----------------

    @NotBlank
    @Size(max = 100)
    @Column(name = "stall_package", nullable = false, length = 100)
    private String stallPackage;

    @NotBlank
    @Size(max = 100)
    @Column(name = "technology_area", nullable = false, length = 100)
    private String technologyArea;

    @NotBlank
    @Size(max = 100)
    @Column(name = "power_requirement", nullable = false, length = 100)
    private String powerRequirement;

    @NotBlank
    @Size(max = 500)
    @Column(name = "products_services", nullable = false, length = 500)
    private String productsServices;

    @Size(max = 1000)
    @Column(name = "special_requirements", columnDefinition = "TEXT")
    private String specialRequirements;

    @Size(max = 1000)
    @Column(name = "remarks", columnDefinition = "TEXT")
    private String remarks;

    @Column(name = "reference_number", unique = true, length = 16)
    private String referenceNumber;

    @Column(name = "email_verified", nullable = false)
    private boolean emailVerified;

    @Column(name = "company_logo_url", length = 500)
    private String companyLogoUrl;

    @Column(name = "document_urls", columnDefinition = "TEXT")
    private String documentUrls;

    @Column(name = "submission_details", columnDefinition = "TEXT")
    private String submissionDetails;

    // ---------------- Audit ----------------

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

    public TecverseRegistration() {
    }

    public TecverseRegistration(Long id, String companyName, String website, String industry, String city,
                                String country, String gstNumber, String companySize, String fullName,
                                String email, String phone, String designation, String linkedinProfile,
                                String stallPackage, String technologyArea, String powerRequirement,
                                String productsServices, String specialRequirements, String remarks,
                                LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.companyName = companyName;
        this.website = website;
        this.industry = industry;
        this.city = city;
        this.country = country;
        this.gstNumber = gstNumber;
        this.companySize = companySize;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.designation = designation;
        this.linkedinProfile = linkedinProfile;
        this.stallPackage = stallPackage;
        this.technologyArea = technologyArea;
        this.powerRequirement = powerRequirement;
        this.productsServices = productsServices;
        this.specialRequirements = specialRequirements;
        this.remarks = remarks;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public String getReferenceNumber() { return referenceNumber; }
    public void setReferenceNumber(String referenceNumber) { this.referenceNumber = referenceNumber; }
    public boolean isEmailVerified() { return emailVerified; }
    public void setEmailVerified(boolean emailVerified) { this.emailVerified = emailVerified; }
    public String getCompanyLogoUrl() { return companyLogoUrl; }
    public void setCompanyLogoUrl(String companyLogoUrl) { this.companyLogoUrl = companyLogoUrl; }
    public String getDocumentUrls() { return documentUrls; }
    public void setDocumentUrls(String documentUrls) { this.documentUrls = documentUrls; }
    public String getSubmissionDetails() { return submissionDetails; }
    public void setSubmissionDetails(String submissionDetails) { this.submissionDetails = submissionDetails; }

    public static TecverseRegistrationBuilder builder() {
        return new TecverseRegistrationBuilder();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getWebsite() {
        return website;
    }

    public void setWebsite(String website) {
        this.website = website;
    }

    public String getIndustry() {
        return industry;
    }

    public void setIndustry(String industry) {
        this.industry = industry;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getGstNumber() {
        return gstNumber;
    }

    public void setGstNumber(String gstNumber) {
        this.gstNumber = gstNumber;
    }

    public String getCompanySize() {
        return companySize;
    }

    public void setCompanySize(String companySize) {
        this.companySize = companySize;
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

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getDesignation() {
        return designation;
    }

    public void setDesignation(String designation) {
        this.designation = designation;
    }

    public String getLinkedinProfile() {
        return linkedinProfile;
    }

    public void setLinkedinProfile(String linkedinProfile) {
        this.linkedinProfile = linkedinProfile;
    }

    public String getStallPackage() {
        return stallPackage;
    }

    public void setStallPackage(String stallPackage) {
        this.stallPackage = stallPackage;
    }

    public String getTechnologyArea() {
        return technologyArea;
    }

    public void setTechnologyArea(String technologyArea) {
        this.technologyArea = technologyArea;
    }

    public String getPowerRequirement() {
        return powerRequirement;
    }

    public void setPowerRequirement(String powerRequirement) {
        this.powerRequirement = powerRequirement;
    }

    public String getProductsServices() {
        return productsServices;
    }

    public void setProductsServices(String productsServices) {
        this.productsServices = productsServices;
    }

    public String getSpecialRequirements() {
        return specialRequirements;
    }

    public void setSpecialRequirements(String specialRequirements) {
        this.specialRequirements = specialRequirements;
    }

    public String getRemarks() {
        return remarks;
    }

    public void setRemarks(String remarks) {
        this.remarks = remarks;
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

    public static class TecverseRegistrationBuilder {
        private Long id;
        private String companyName;
        private String website;
        private String industry;
        private String city;
        private String country;
        private String gstNumber;
        private String companySize;
        private String fullName;
        private String email;
        private String phone;
        private String designation;
        private String linkedinProfile;
        private String stallPackage;
        private String technologyArea;
        private String powerRequirement;
        private String productsServices;
        private String specialRequirements;
        private String remarks;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;

        public TecverseRegistrationBuilder id(Long id) { this.id = id; return this; }
        public TecverseRegistrationBuilder companyName(String companyName) { this.companyName = companyName; return this; }
        public TecverseRegistrationBuilder website(String website) { this.website = website; return this; }
        public TecverseRegistrationBuilder industry(String industry) { this.industry = industry; return this; }
        public TecverseRegistrationBuilder city(String city) { this.city = city; return this; }
        public TecverseRegistrationBuilder country(String country) { this.country = country; return this; }
        public TecverseRegistrationBuilder gstNumber(String gstNumber) { this.gstNumber = gstNumber; return this; }
        public TecverseRegistrationBuilder companySize(String companySize) { this.companySize = companySize; return this; }
        public TecverseRegistrationBuilder fullName(String fullName) { this.fullName = fullName; return this; }
        public TecverseRegistrationBuilder email(String email) { this.email = email; return this; }
        public TecverseRegistrationBuilder phone(String phone) { this.phone = phone; return this; }
        public TecverseRegistrationBuilder designation(String designation) { this.designation = designation; return this; }
        public TecverseRegistrationBuilder linkedinProfile(String linkedinProfile) { this.linkedinProfile = linkedinProfile; return this; }
        public TecverseRegistrationBuilder stallPackage(String stallPackage) { this.stallPackage = stallPackage; return this; }
        public TecverseRegistrationBuilder technologyArea(String technologyArea) { this.technologyArea = technologyArea; return this; }
        public TecverseRegistrationBuilder powerRequirement(String powerRequirement) { this.powerRequirement = powerRequirement; return this; }
        public TecverseRegistrationBuilder productsServices(String productsServices) { this.productsServices = productsServices; return this; }
        public TecverseRegistrationBuilder specialRequirements(String specialRequirements) { this.specialRequirements = specialRequirements; return this; }
        public TecverseRegistrationBuilder remarks(String remarks) { this.remarks = remarks; return this; }
        public TecverseRegistrationBuilder createdAt(LocalDateTime createdAt) { this.createdAt = createdAt; return this; }
        public TecverseRegistrationBuilder updatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public TecverseRegistration build() {
            return new TecverseRegistration(id, companyName, website, industry, city, country, gstNumber,
                    companySize, fullName, email, phone, designation, linkedinProfile, stallPackage,
                    technologyArea, powerRequirement, productsServices, specialRequirements, remarks,
                    createdAt, updatedAt);
        }
    }
}
