package com.tecverse.app.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class TicketOtpSendRequest {

    @NotBlank(message = "{validation.fullName.required}")
    @Size(max = 150)
    @Pattern(regexp = "^[\\p{L}\\p{M}][\\p{L}\\p{M} .,'’\\-]{0,149}$", message = "Use letters, spaces, periods, apostrophes, commas, or hyphens for your name.")
    private String fullName;

    @NotBlank(message = "{validation.email.required}")
    @Email(message = "{validation.email}")
    @Size(max = 150)
    private String email;

    @NotBlank
    @Size(max = 20)
    @Pattern(regexp = "^(?:\\+91[-\\s]?)?[6-9]\\d{9}$", message = "Enter a valid 10-digit Indian mobile number.")
    private String phone;

    @Size(max = 80)
    @Pattern(regexp = "^[\\p{L}\\p{N} .\\-]*$", message = "Enter a valid pass type.")
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
