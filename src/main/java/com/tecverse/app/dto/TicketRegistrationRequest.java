package com.tecverse.app.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.AssertTrue;

import java.util.List;

public class TicketRegistrationRequest {
    @NotBlank @Size(max=150, message="Name must be 150 characters or fewer.")
    @Pattern(regexp="^[\\p{L}\\p{M}][\\p{L}\\p{M} .,'’\\-]{0,149}$", message="Use letters, spaces, periods, apostrophes, commas, or hyphens for your name.")
    private String officialName;
    @NotBlank @Email @Size(max=150, message="Email must be 150 characters or fewer.")
    private String email;
    @NotBlank @Pattern(regexp="^(?:\\+91[-\\s]?)?[6-9]\\d{9}$", message="Enter a valid 10-digit Indian mobile number.") @Size(max=15)
    private String phone;
    @NotBlank
    @Size(min=8, max=64, message="Password must be between 8 and 64 characters.")
    @Pattern(regexp="^(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9\\s])(?=.{8,64}$).*$",
            message="Password must contain at least 8 characters, one uppercase letter, one number, and one special symbol.")
    private String password;
    @NotBlank @Size(max=64, message="Confirm password must be 64 characters or fewer.")
    private String confirmPassword;
    @NotBlank @Pattern(regexp="ACADEMIA|CENTRAL_GOVERNMENT|STATE_GOVERNMENT|INDUSTRY_STARTUP|VIP_SPECIAL_INVITEE|SPEAKER|ORGANIZER", message="Choose a valid registration category.")
    private String category;
    @Size(max=100) @Pattern(regexp="^(?:(?=.*\\p{L})[\\p{L}\\p{M}\\p{N}][\\p{L}\\p{M}\\p{N} &.,'’()/#+-]{0,99})?$", message="Academia type must contain letters.") private String academiaType;
    @Size(max=200) @Pattern(regexp="^(?:(?=.*\\p{L})[\\p{L}\\p{M}\\p{N}][\\p{L}\\p{M}\\p{N} &.,'’()/#+-]{0,199})?$", message="Institution name must contain letters and may include numbers, spaces, and common punctuation (& . , ' - / # + parentheses).") private String collegeName;
    @Size(max=100) @Pattern(regexp="^(?:[\\p{L}\\p{M}][\\p{L}\\p{M} .,'’()/-]{0,99})?$", message="Enter a valid district name using letters and common punctuation.") private String collegeDistrict;
    @Size(max=100) @Pattern(regexp="^(?:[\\p{L}\\p{M}][\\p{L}\\p{M} .,'’()/-]{0,99})?$", message="Enter a valid state or union territory name using letters and common punctuation.") private String collegeState;
    @Size(max=200) @Pattern(regexp="^(?:(?=.*\\p{L})[\\p{L}\\p{M}\\p{N}][\\p{L}\\p{M}\\p{N} &.,'’()/#+-]{0,199})?$", message="University name must contain letters and may include numbers, spaces, and common punctuation (& . , ' - / # + parentheses).") private String universityName;
    @Size(max=100) private String academiaRole;
    @Size(max=100) @Pattern(regexp="^(?:[\\p{L}\\p{M}\\p{N}][\\p{L}\\p{M}\\p{N} _./#-]{0,99})?$", message="Student ID may contain letters, numbers, spaces, and these separators: _ . / # -.") private String registerNumber;

    @Size(max=200) private String centralMinistry;
    @Size(max=100) private String stateName;
    @Size(max=200) private String stateDepartment;

    @Size(max=200) @Pattern(regexp="^(?:(?=.*\\p{L})[\\p{L}\\p{M}\\p{N}][\\p{L}\\p{M}\\p{N} &.,'’()/#+-]{0,199})?$", message="Organization name must contain letters and may include numbers, spaces, and common punctuation (& . , ' - / # + parentheses).") private String organizationName;
    @Size(max=255) @Pattern(regexp="^(?:[\\p{L}\\p{M}][\\p{L}\\p{M} .,'’()/-]{0,254})?$", message="Enter a valid city or office location using letters, spaces, and common punctuation.") private String organizationLocation;
    @Size(max=150) @Pattern(regexp="^(?:[\\p{L}\\p{M}][\\p{L}\\p{M} &.,'’()/-]{0,149})?$", message="Designation may contain letters, spaces, and common punctuation (& . , ' - / parentheses).") private String designation;
    @Size(max=100) private String industryOrStartup;

    @NotBlank @Pattern(regexp="INDIAN|NRI|FOREIGNER", message="Choose a valid citizenship status.")
    private String citizenshipStatus;
    @NotBlank @Pattern(regexp="^(?:Andhra Pradesh|Arunachal Pradesh|Assam|Bihar|Chhattisgarh|Goa|Gujarat|Haryana|Himachal Pradesh|Jharkhand|Karnataka|Kerala|Madhya Pradesh|Maharashtra|Manipur|Meghalaya|Mizoram|Nagaland|Odisha|Punjab|Rajasthan|Sikkim|Tamil Nadu|Telangana|Tripura|Uttar Pradesh|Uttarakhand|West Bengal|Andaman and Nicobar Islands|Chandigarh|Dadra and Nagar Haveli and Daman and Diu|Delhi|Jammu and Kashmir|Ladakh|Lakshadweep|Puducherry)$", message="Select a valid state or union territory.")
    private String applicantState;
    @Size(max=50) @Pattern(regexp="^(?:[A-Za-z0-9][A-Za-z0-9-]{0,49})?$", message="Passport number may contain letters, numbers, and hyphens.") private String passportNumber;
    @Size(max=10) private String passportValidUntil;
    @Size(max=150) @Pattern(regexp="^(?:[\\p{L}\\p{M}][\\p{L}\\p{M} .,'’\\-]{0,149})?$", message="Use letters, spaces, periods, apostrophes, commas, or hyphens for the passport name.") private String passportName;

    @jakarta.validation.constraints.NotEmpty(message="Select at least one attendance day.")
    private List<@Pattern(regexp="DAY_1|DAY_2|BOTH", message="Choose a valid attendance day.") String> attendanceDays;

    @AssertTrue(message="Password and confirm password must match.")
    public boolean isPasswordConfirmationValid() {
        return password == null || confirmPassword == null || password.equals(confirmPassword);
    }

    public String getOfficialName(){return officialName;} public void setOfficialName(String v){this.officialName=v;}
    public String getEmail(){return email;} public void setEmail(String v){this.email=v;}
    public String getPhone(){return phone;} public void setPhone(String v){this.phone=v;}
    public String getPassword(){return password;} public void setPassword(String v){this.password=v;}
    public String getConfirmPassword(){return confirmPassword;} public void setConfirmPassword(String v){this.confirmPassword=v;}
    public String getCategory(){return category;} public void setCategory(String v){this.category=v;}
    public String getAcademiaType(){return academiaType;} public void setAcademiaType(String v){this.academiaType=v;}
    public String getCollegeName(){return collegeName;} public void setCollegeName(String v){this.collegeName=v;}
    public String getCollegeDistrict(){return collegeDistrict;} public void setCollegeDistrict(String v){this.collegeDistrict=v;}
    public String getCollegeState(){return collegeState;} public void setCollegeState(String v){this.collegeState=v;}
    public String getUniversityName(){return universityName;} public void setUniversityName(String v){this.universityName=v;}
    public String getAcademiaRole(){return academiaRole;} public void setAcademiaRole(String v){this.academiaRole=v;}
    public String getRegisterNumber(){return registerNumber;} public void setRegisterNumber(String v){this.registerNumber=v;}
    public String getCentralMinistry(){return centralMinistry;} public void setCentralMinistry(String v){this.centralMinistry=v;}
    public String getStateName(){return stateName;} public void setStateName(String v){this.stateName=v;}
    public String getStateDepartment(){return stateDepartment;} public void setStateDepartment(String v){this.stateDepartment=v;}
    public String getOrganizationName(){return organizationName;} public void setOrganizationName(String v){this.organizationName=v;}
    public String getOrganizationLocation(){return organizationLocation;} public void setOrganizationLocation(String v){this.organizationLocation=v;}
    public String getDesignation(){return designation;} public void setDesignation(String v){this.designation=v;}
    public String getIndustryOrStartup(){return industryOrStartup;} public void setIndustryOrStartup(String v){this.industryOrStartup=v;}
    public String getCitizenshipStatus(){return citizenshipStatus;} public void setCitizenshipStatus(String v){this.citizenshipStatus=v;}
    public String getApplicantState(){return applicantState;} public void setApplicantState(String v){this.applicantState=v;}
    public String getPassportNumber(){return passportNumber;} public void setPassportNumber(String v){this.passportNumber=v;}
    public String getPassportValidUntil(){return passportValidUntil;} public void setPassportValidUntil(String v){this.passportValidUntil=v;}
    public String getPassportName(){return passportName;} public void setPassportName(String v){this.passportName=v;}
    public List<String> getAttendanceDays(){return attendanceDays;} public void setAttendanceDays(List<String> v){this.attendanceDays=v;}
}
