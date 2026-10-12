package com.tecverse.app.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class InquiryForm {
    @NotBlank(message = "{validation.fullName.required}")
    @Size(max=150, message="Maximum 150 characters allowed.")
    private String name;

    @NotBlank(message = "{validation.email.required}")
    @Email(message = "{validation.email}")
    @Size(max=255, message="Maximum 255 characters allowed.")
    private String email;

    @NotBlank(message = "{validation.phone.required}")
    @Size(max=32, message="Maximum 32 characters allowed.")
    private String phone;

    @NotBlank(message = "{validation.companyName.required}")
    @Size(max=200, message="Maximum 200 characters allowed.")
    private String company;

    @Size(max=150, message="Maximum 150 characters allowed.")
    private String jobTitle;
    @Size(max=2, message="Maximum 2 characters allowed.")
    private String country = "IN";
    @Size(max=150, message="Maximum 150 characters allowed.")
    private String sponsorshipInterest;

    @NotBlank(message = "{validation.message.required}")
    @Size(max=5000, message="Maximum 5000 characters allowed.")
    private String message;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name == null ? null : name.strip();
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email == null ? null : email.strip();
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone == null ? null : phone.strip();
    }

    public String getCompany() {
        return company;
    }

    public void setCompany(String company) {
        this.company = company == null ? null : company.strip();
    }

    public String getJobTitle() {
        return jobTitle;
    }

    public void setJobTitle(String jobTitle) {
        this.jobTitle = jobTitle == null ? null : jobTitle.strip();
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country == null ? null : country.strip();
    }

    public String getSponsorshipInterest() {
        return sponsorshipInterest;
    }

    public void setSponsorshipInterest(String sponsorshipInterest) {
        this.sponsorshipInterest = sponsorshipInterest == null ? null : sponsorshipInterest.strip();
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message == null ? null : message.strip();
    }
}

