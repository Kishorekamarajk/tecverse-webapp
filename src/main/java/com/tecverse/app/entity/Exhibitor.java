package com.tecverse.app.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "exhibitor")
public class Exhibitor {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "reference_number", nullable = false, unique = true, length = 16)
    private String referenceNumber;
    @Column(name = "company_name", nullable = false, length = 200)
    private String companyName;
    @Column(length = 100)
    private String industry;
    @Column(length = 255)
    private String website;
    @Column(name = "company_address", length = 500)
    private String companyAddress;
    @Column(length = 100)
    private String city;
    @Column(length = 100)
    private String state;
    @Column(length = 100)
    private String country;
    @Column(name = "gst_number", length = 15)
    private String gst;
    @Column(name = "company_registration_number", length = 100)
    private String companyRegistrationNumber;
    @Column(name = "linkedin_profile", length = 255)
    private String linkedin;
    @Column(name = "company_description", columnDefinition = "TEXT")
    private String companyDescription;
    @Column(name = "product_service_category", length = 150)
    private String productServiceCategory;
    @Column(name = "full_name", nullable = false, length = 150)
    private String fullName;
    @Column(nullable = false, length = 100)
    private String designation;
    @Column(nullable = false, length = 20)
    private String phone;
    @Column(name = "whatsapp_number", length = 20)
    private String whatsappNumber;
    @Column(nullable = false, length = 254)
    private String email;
    @Column(name = "alternate_contact_person", length = 150)
    private String alternateContactPerson;
    @Column(name = "alternate_mobile_number", length = 20)
    private String alternateMobileNumber;
    @Column(nullable = false, length = 100)
    private String products;
    @Column(name = "product_technology_name", length = 200)
    private String productTechnologyName;
    @Column(name = "product_category", length = 150)
    private String productCategory;
    @Column(name = "product_description", columnDefinition = "TEXT")
    private String productDescription;
    @Column(name = "product_stage", length = 100)
    private String productStage;
    @Column(name = "special_requirements", columnDefinition = "TEXT")
    private String specialRequirements;
    @Column(name = "machinery_equipment", columnDefinition = "TEXT")
    private String machineryEquipment;
    @Column(name = "equipment_dimensions", length = 150)
    private String equipmentDimensions;
    @Column(name = "equipment_weight", length = 100)
    private String equipmentWeight;
    @Column(name = "utility_requirements", columnDefinition = "TEXT")
    private String utilityRequirements;
    @Column(name = "equipment_impact", columnDefinition = "TEXT")
    private String equipmentImpact;
    @Column(name = "stall_package", nullable = false, length = 100)
    private String stallPackage;
    @Column(name = "power_requirement", length = 100)
    private String powerRequirement;
    @Column(name = "technology_area", length = 100)
    private String technologyArea;
    @Column(name = "company_size", length = 100)
    private String companySize;
    @Column(columnDefinition = "TEXT")
    private String remarks;
    @Column(name = "company_logo_path", length = 1000)
    private String companyLogoPath;
    @Column(name = "document_one_path", length = 1000)
    private String documentOnePath;
    @Column(name = "document_two_path", length = 1000)
    private String documentTwoPath;
    @Column(name = "document_urls", columnDefinition = "TEXT")
    private String documentUrls;
    @Column(name = "email_verified", nullable = false)
    private boolean emailVerified;
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public Exhibitor() {
    }

    public Long getId() { return id; }
    public String getReferenceNumber() { return referenceNumber; }
    public String getCompanyName() { return companyName; }
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
    public String getDesignation() { return designation; }
    public String getIndustry() { return industry; }
    public String getWebsite() { return website; }
    public String getCompanyAddress() { return companyAddress; }
    public String getCity() { return city; }
    public String getState() { return state; }
    public String getCountry() { return country; }
    public String getProducts() { return products; }
    public String getProductCategory() { return productCategory; }
    public String getProductDescription() { return productDescription; }
    public String getStallPackage() { return stallPackage; }
    public String getRemarks() { return remarks; }
    public LocalDateTime getCreatedAt() { return createdAt; }

    public void setReferenceNumber(String value) { referenceNumber = value; }
    public void setCompanyName(String value) { companyName = value; }
    public void setIndustry(String value) { industry = value; }
    public void setWebsite(String value) { website = value; }
    public void setCompanyAddress(String value) { companyAddress = value; }
    public void setCity(String value) { city = value; }
    public void setState(String value) { state = value; }
    public void setCountry(String value) { country = value; }
    public void setGst(String value) { gst = value; }
    public void setCompanyRegistrationNumber(String value) { companyRegistrationNumber = value; }
    public void setLinkedin(String value) { linkedin = value; }
    public void setCompanyDescription(String value) { companyDescription = value; }
    public void setProductServiceCategory(String value) { productServiceCategory = value; }
    public void setFullName(String value) { fullName = value; }
    public void setDesignation(String value) { designation = value; }
    public void setPhone(String value) { phone = value; }
    public void setWhatsappNumber(String value) { whatsappNumber = value; }
    public void setEmail(String value) { email = value; }
    public void setAlternateContactPerson(String value) { alternateContactPerson = value; }
    public void setAlternateMobileNumber(String value) { alternateMobileNumber = value; }
    public void setProducts(String value) { products = value; }
    public void setProductTechnologyName(String value) { productTechnologyName = value; }
    public void setProductCategory(String value) { productCategory = value; }
    public void setProductDescription(String value) { productDescription = value; }
    public void setProductStage(String value) { productStage = value; }
    public void setSpecialRequirements(String value) { specialRequirements = value; }
    public void setMachineryEquipment(String value) { machineryEquipment = value; }
    public void setEquipmentDimensions(String value) { equipmentDimensions = value; }
    public void setEquipmentWeight(String value) { equipmentWeight = value; }
    public void setUtilityRequirements(String value) { utilityRequirements = value; }
    public void setEquipmentImpact(String value) { equipmentImpact = value; }
    public void setStallPackage(String value) { stallPackage = value; }
    public void setPowerRequirement(String value) { powerRequirement = value; }
    public void setTechnologyArea(String value) { technologyArea = value; }
    public void setCompanySize(String value) { companySize = value; }
    public void setRemarks(String value) { remarks = value; }
    public void setCompanyLogoPath(String value) { companyLogoPath = value; }
    public void setDocumentOnePath(String value) { documentOnePath = value; }
    public void setDocumentTwoPath(String value) { documentTwoPath = value; }
    public void setDocumentUrls(String value) { documentUrls = value; }
    public String getCompanyLogoPath() { return companyLogoPath; }
    public String getDocumentOnePath() { return documentOnePath; }
    public String getDocumentTwoPath() { return documentTwoPath; }
    public String getDocumentUrls() { return documentUrls; }
    public void setEmailVerified(boolean value) { emailVerified = value; }
    public void setCreatedAt(LocalDateTime value) { createdAt = value; }
    public void setUpdatedAt(LocalDateTime value) { updatedAt = value; }
}
