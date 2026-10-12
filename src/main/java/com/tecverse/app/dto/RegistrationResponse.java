package com.tecverse.app.dto;

import java.time.LocalDateTime;

/**
 * What the client receives back after a successful {@code POST /register}.
 */
public class RegistrationResponse {

    private Long id;
    private String companyName;
    private String email;
    private String phone;
    private String stallPackage;
    private LocalDateTime createdAt;
    private String referenceNumber;

    public RegistrationResponse() {
    }

    public RegistrationResponse(Long id, String companyName, String email, String phone,
                                 String stallPackage, LocalDateTime createdAt) {
        this.id = id;
        this.companyName = companyName;
        this.email = email;
        this.phone = phone;
        this.stallPackage = stallPackage;
        this.createdAt = createdAt;
    }

    public static RegistrationResponseBuilder builder() {
        return new RegistrationResponseBuilder();
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

    public String getStallPackage() {
        return stallPackage;
    }

    public void setStallPackage(String stallPackage) {
        this.stallPackage = stallPackage;
    }

    public String getReferenceNumber() { return referenceNumber; }
    public void setReferenceNumber(String referenceNumber) { this.referenceNumber = referenceNumber; }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public static class RegistrationResponseBuilder {
        private Long id;
        private String companyName;
        private String email;
        private String phone;
        private String stallPackage;
        private LocalDateTime createdAt;
        private String referenceNumber;

        public RegistrationResponseBuilder id(Long id) {
            this.id = id;
            return this;
        }

        public RegistrationResponseBuilder companyName(String companyName) {
            this.companyName = companyName;
            return this;
        }

        public RegistrationResponseBuilder email(String email) {
            this.email = email;
            return this;
        }

        public RegistrationResponseBuilder phone(String phone) {
            this.phone = phone;
            return this;
        }

        public RegistrationResponseBuilder stallPackage(String stallPackage) {
            this.stallPackage = stallPackage;
            return this;
        }

        public RegistrationResponseBuilder referenceNumber(String referenceNumber) { this.referenceNumber = referenceNumber; return this; }

        public RegistrationResponseBuilder createdAt(LocalDateTime createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public RegistrationResponse build() {
            RegistrationResponse r = new RegistrationResponse(id, companyName, email, phone, stallPackage, createdAt); r.setReferenceNumber(referenceNumber); return r;
        }
    }
}
