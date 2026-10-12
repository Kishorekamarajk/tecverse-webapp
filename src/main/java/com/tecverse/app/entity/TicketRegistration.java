package com.tecverse.app.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name="tecverse_ticket_registrations",
    uniqueConstraints={
      @UniqueConstraint(name="uk_ticket_reference", columnNames="reference_number"),
      @UniqueConstraint(name="uk_ticket_scan_token", columnNames="scan_token"),
      @UniqueConstraint(name="uk_ticket_email", columnNames="email"),
      @UniqueConstraint(name="uk_ticket_phone", columnNames="phone")
    },
    indexes={
      @Index(name="idx_ticket_category", columnList="category"),
      @Index(name="idx_ticket_created_at", columnList="created_at")
    })
public class TicketRegistration {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY)
    private Long id;
    @Column(name="reference_number",nullable=false,length=12) private String referenceNumber;
    @Column(name="scan_token",nullable=false,length=32) private String scanToken;
    @Column(name="official_name",nullable=false,length=150) private String officialName;
    @Column(nullable=false,length=150) private String email;
    @Column(nullable=false,length=20) private String phone;
    @Column(name="password_hash",length=60) private String passwordHash;
    @Column(nullable=false,length=40) private String category;
    @Column(name="academia_type",length=30) private String academiaType;
    @Column(name="college_name",length=250) private String collegeName;
    @Column(name="college_district",length=120) private String collegeDistrict;
    @Column(name="college_state",length=120) private String collegeState;
    @Column(name="university_name",length=250) private String universityName;
    @Column(name="academia_role",length=30) private String academiaRole;
    @Column(name="register_number",length=100) private String registerNumber;
    @Column(name="central_ministry",length=250) private String centralMinistry;
    @Column(name="state_name",length=120) private String stateName;
    @Column(name="state_department",length=250) private String stateDepartment;
    @Column(name="organization_name",length=250) private String organizationName;
    @Column(name="organization_location",length=250) private String organizationLocation;
    @Column(length=150) private String designation;
    @Column(name="industry_or_startup",length=30) private String industryOrStartup;
    @Column(name="citizenship_status",nullable=false,length=20) private String citizenshipStatus;
    @Column(name="passport_number",length=50) private String passportNumber;
    @Column(name="passport_valid_until",length=30) private String passportValidUntil;
    @Column(name="passport_name",length=150) private String passportName;
    @Column(name="attendance_days",nullable=false,length=100) private String attendanceDays;
    @Column(name="confirmation_email_sent",nullable=false,columnDefinition="boolean default true") private boolean confirmationEmailSent = true;
    @Column(name="confirmation_email_attempts",nullable=false,columnDefinition="integer default 0") private int confirmationEmailAttempts;
    @Column(name="created_at",nullable=false) private LocalDateTime createdAt;
    @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;

    @PrePersist void create(){LocalDateTime n=LocalDateTime.now();createdAt=n;updatedAt=n;}
    @PreUpdate void update(){updatedAt=LocalDateTime.now();}

    public Long getId(){return id;} public String getReferenceNumber(){return referenceNumber;} public String getScanToken(){return scanToken;}
    public String getOfficialName(){return officialName;} public String getEmail(){return email;} public String getPhone(){return phone;}
    public String getPasswordHash(){return passwordHash;}
    public String getCategory(){return category;} public String getAcademiaType(){return academiaType;} public String getCollegeName(){return collegeName;}
    public String getCollegeDistrict(){return collegeDistrict;} public String getCollegeState(){return collegeState;} public String getUniversityName(){return universityName;}
    public String getAcademiaRole(){return academiaRole;} public String getRegisterNumber(){return registerNumber;} public String getCentralMinistry(){return centralMinistry;}
    public String getStateName(){return stateName;} public String getStateDepartment(){return stateDepartment;} public String getOrganizationName(){return organizationName;}
    public String getOrganizationLocation(){return organizationLocation;} public String getDesignation(){return designation;} public String getIndustryOrStartup(){return industryOrStartup;}
    public String getCitizenshipStatus(){return citizenshipStatus;} public String getPassportNumber(){return passportNumber;} public String getPassportValidUntil(){return passportValidUntil;}
    public String getPassportName(){return passportName;} public String getAttendanceDays(){return attendanceDays;} public LocalDateTime getCreatedAt(){return createdAt;}
    public boolean isConfirmationEmailSent(){return confirmationEmailSent;} public int getConfirmationEmailAttempts(){return confirmationEmailAttempts;}

    public void setReferenceNumber(String v){referenceNumber=v;} public void setScanToken(String v){scanToken=v;} public void setOfficialName(String v){officialName=v;} public void setEmail(String v){email=v;}
    public void setPhone(String v){phone=v;} public void setCategory(String v){category=v;} public void setAcademiaType(String v){academiaType=v;}
    public void setPasswordHash(String v){passwordHash=v;}
    public void setCollegeName(String v){collegeName=v;} public void setCollegeDistrict(String v){collegeDistrict=v;} public void setCollegeState(String v){collegeState=v;}
    public void setUniversityName(String v){universityName=v;} public void setAcademiaRole(String v){academiaRole=v;} public void setRegisterNumber(String v){registerNumber=v;}
    public void setCentralMinistry(String v){centralMinistry=v;} public void setStateName(String v){stateName=v;} public void setStateDepartment(String v){stateDepartment=v;}
    public void setOrganizationName(String v){organizationName=v;} public void setOrganizationLocation(String v){organizationLocation=v;} public void setDesignation(String v){designation=v;}
    public void setIndustryOrStartup(String v){industryOrStartup=v;} public void setCitizenshipStatus(String v){citizenshipStatus=v;} public void setPassportNumber(String v){passportNumber=v;}
    public void setPassportValidUntil(String v){passportValidUntil=v;} public void setPassportName(String v){passportName=v;} public void setAttendanceDays(String v){attendanceDays=v;}
    public void setConfirmationEmailSent(boolean v){confirmationEmailSent=v;} public void setConfirmationEmailAttempts(int v){confirmationEmailAttempts=v;}
}
