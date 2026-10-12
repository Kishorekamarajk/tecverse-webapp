package com.tecverse.app.dto;

import java.util.List;

import com.tecverse.app.util.Constants;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Complete TEC-VERSE exhibitor application payload. */
public class RegistrationRequest {
    @NotBlank(message="Company name is required.") @Size(max=200) private String companyName;
    @NotBlank(message="Company type or industry is required.") @Size(max=100) private String industry;
    @Pattern(regexp="^$|^https?://.+", message="Enter a valid website URL starting with http:// or https://.") @Size(max=255) private String website;
    @Size(max=500) private String companyAddress;
    @NotBlank(message="City is required.") @Size(max=100) private String city;
    @NotBlank(message="State is required.") @Size(max=100) private String state;
    @NotBlank(message="Country is required.") @Size(max=100) private String country;
    @Pattern(regexp="^$|" + Constants.GSTIN_REGEX, message="Enter a valid 15-character GSTIN.") @Size(max=15) private String gst;
    @Size(max=100) private String companyRegistrationNumber;
    @Pattern(regexp=Constants.LINKEDIN_REGEX, message="Enter a valid LinkedIn URL.") @Size(max=255) private String linkedin;
    @Size(max=1000) private String companyLogoUrl;
    @Size(max=1000) private String companyDescription;
    @Size(max=150) private String productServiceCategory;
    @NotBlank(message="Contact person's name is required.") @Pattern(regexp=Constants.FULL_NAME_REGEX, message="Enter a valid contact name.") @Size(max=150) private String fullName;
    @NotBlank(message="Designation is required.") @Size(max=100) private String designation;
    @NotBlank(message="Mobile number is required.") @Pattern(regexp=Constants.INDIAN_MOBILE_REGEX, message="Enter a valid 10-digit Indian mobile number.") @Size(max=15) private String phone;
    @Pattern(regexp="^$|" + Constants.INDIAN_MOBILE_REGEX, message="Enter a valid WhatsApp number.") @Size(max=15) private String whatsappNumber;
    @NotBlank(message="Official email is required.") @Email(message="Enter a valid official email address.") @Size(max=254) private String email;
    @Size(max=150) private String alternateContactPerson;
    @Pattern(regexp="^$|" + Constants.INDIAN_MOBILE_REGEX, message="Enter a valid alternate mobile number.") @Size(max=15) private String alternateMobileNumber;
    @NotBlank(message="Select what you are exhibiting.") @Size(max=100) private String products;
    @Size(max=150) private String productTechnologyName;
    @Size(max=100) private String productCategory;
    @Size(max=2000) private String productDescription;
    @Size(max=100) private String productStage;
    @Size(max=500) private String specialRequirements;
    @Size(max=500) private String machineryEquipment;
    @Size(max=100) private String equipmentDimensions;
    @Size(max=100) private String equipmentWeight;
    @Size(max=1000) private String utilityRequirements;
    @Size(max=1000) private String equipmentImpact;
    @NotBlank(message="Select a stall package.") @Pattern(regexp="^(3 × 3 Mtr\\.|3 × 6 Mtr\\.|6 × 6 Mtr\\.)$", message="Select a valid stall package.") private String stallPackage;
    @Size(max=200) private String powerRequirement;
    @Size(max=150) private String technologyArea;
    @Size(max=100) private String companySize;
    @Size(max=2000) private String remarks;
    @Size(max=2, message="A maximum of 2 supporting documents is allowed.") private List<String> documentUrls;

    public String getCompanyName(){return companyName;} public void setCompanyName(String v){companyName=v;}
    public String getIndustry(){return industry;} public void setIndustry(String v){industry=v;}
    public String getWebsite(){return website;} public void setWebsite(String v){website=v;}
    public String getCompanyAddress(){return companyAddress;} public void setCompanyAddress(String v){companyAddress=v;}
    public String getCity(){return city;} public void setCity(String v){city=v;}
    public String getState(){return state;} public void setState(String v){state=v;}
    public String getCountry(){return country;} public void setCountry(String v){country=v;}
    public String getGst(){return gst;} public void setGst(String v){gst=v;}
    public String getCompanyRegistrationNumber(){return companyRegistrationNumber;} public void setCompanyRegistrationNumber(String v){companyRegistrationNumber=v;}
    public String getLinkedin(){return linkedin;} public void setLinkedin(String v){linkedin=v;}
    public String getCompanyLogoUrl(){return companyLogoUrl;} public void setCompanyLogoUrl(String v){companyLogoUrl=v;}
    public String getCompanyDescription(){return companyDescription;} public void setCompanyDescription(String v){companyDescription=v;}
    public String getProductServiceCategory(){return productServiceCategory;} public void setProductServiceCategory(String v){productServiceCategory=v;}
    public String getFullName(){return fullName;} public void setFullName(String v){fullName=v;}
    public String getDesignation(){return designation;} public void setDesignation(String v){designation=v;}
    public String getPhone(){return phone;} public void setPhone(String v){phone=v;}
    public String getWhatsappNumber(){return whatsappNumber;} public void setWhatsappNumber(String v){whatsappNumber=v;}
    public String getEmail(){return email;} public void setEmail(String v){email=v;}
    public String getAlternateContactPerson(){return alternateContactPerson;} public void setAlternateContactPerson(String v){alternateContactPerson=v;}
    public String getAlternateMobileNumber(){return alternateMobileNumber;} public void setAlternateMobileNumber(String v){alternateMobileNumber=v;}
    public String getProducts(){return products;} public void setProducts(String v){products=v;}
    public String getProductTechnologyName(){return productTechnologyName;} public void setProductTechnologyName(String v){productTechnologyName=v;}
    public String getProductCategory(){return productCategory;} public void setProductCategory(String v){productCategory=v;}
    public String getProductDescription(){return productDescription;} public void setProductDescription(String v){productDescription=v;}
    public String getProductStage(){return productStage;} public void setProductStage(String v){productStage=v;}
    public String getSpecialRequirements(){return specialRequirements;} public void setSpecialRequirements(String v){specialRequirements=v;}
    public String getMachineryEquipment(){return machineryEquipment;} public void setMachineryEquipment(String v){machineryEquipment=v;}
    public String getEquipmentDimensions(){return equipmentDimensions;} public void setEquipmentDimensions(String v){equipmentDimensions=v;}
    public String getEquipmentWeight(){return equipmentWeight;} public void setEquipmentWeight(String v){equipmentWeight=v;}
    public String getUtilityRequirements(){return utilityRequirements;} public void setUtilityRequirements(String v){utilityRequirements=v;}
    public String getEquipmentImpact(){return equipmentImpact;} public void setEquipmentImpact(String v){equipmentImpact=v;}
    public String getStallPackage(){return stallPackage;} public void setStallPackage(String v){stallPackage=v;}
    public String getPowerRequirement(){return powerRequirement;} public void setPowerRequirement(String v){powerRequirement=v;}
    public String getTechnologyArea(){return technologyArea;} public void setTechnologyArea(String v){technologyArea=v;}
    public String getCompanySize(){return companySize;} public void setCompanySize(String v){companySize=v;}
    public String getRemarks(){return remarks;} public void setRemarks(String v){remarks=v;}
    public List<String> getDocumentUrls(){return documentUrls;} public void setDocumentUrls(List<String> v){documentUrls=v;}
}
