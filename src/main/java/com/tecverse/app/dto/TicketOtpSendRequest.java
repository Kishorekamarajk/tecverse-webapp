package com.tecverse.app.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class TicketOtpSendRequest {

    @NotBlank(message = "{validation.fullName.required}")
    @Size(max = 150)
    private String fullName;

    @NotBlank(message = "{validation.email.required}")
    @Email(message = "{validation.email}")
    @Size(max = 150)
    private String email;

    @NotBlank
    @Size(max = 20)
    private String phone;

    @Size(max = 80)
    private String passType;

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

    public String getPassType() {
        return passType;
    }

    public void setPassType(String passType) {
        this.passType = passType;
    }
}
