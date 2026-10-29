package com.tecverse.app.service.impl;

import java.time.LocalDateTime;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tecverse.app.dto.RegistrationRequest;
import com.tecverse.app.dto.RegistrationResponse;
import com.tecverse.app.event.ExhibitorRegistrationSavedEvent;
import com.tecverse.app.entity.Exhibitor;
import com.tecverse.app.entity.TecverseRegistration;
import com.tecverse.app.exception.DuplicateEmailException;
import com.tecverse.app.exception.DuplicatePhoneException;
import com.tecverse.app.repository.ExhibitorRepository;
import com.tecverse.app.repository.TecverseRegistrationRepository;
import com.tecverse.app.service.ExhibitorOtpService;
import com.tecverse.app.service.RegistrationService;
import com.tecverse.app.service.TicketRegistrationReferenceService;
import com.tecverse.app.util.ValidationUtil;

@Service
public class RegistrationServiceImpl implements RegistrationService {
    private final TecverseRegistrationRepository repo;
    private final ExhibitorRepository exhibitorRepo;
    private final ExhibitorOtpService otp;
    private final ObjectMapper json;
    private final TicketRegistrationReferenceService referenceService;
    private final ApplicationEventPublisher eventPublisher;

    public RegistrationServiceImpl(TecverseRegistrationRepository repo,
                                   ExhibitorRepository exhibitorRepo,
                                   ExhibitorOtpService otp,
                                   ObjectMapper json,
                                   TicketRegistrationReferenceService referenceService,
                                   ApplicationEventPublisher eventPublisher) {
        this.repo = repo;
        this.exhibitorRepo = exhibitorRepo;
        this.otp = otp;
        this.json = json;
        this.referenceService = referenceService;
        this.eventPublisher = eventPublisher;
    }

    @Override
    @Transactional
    public RegistrationResponse register(RegistrationRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        String phone = ValidationUtil.normalizeIndianMobile(request.getPhone());

        if (!otp.isVerified(email)) {
            throw new IllegalArgumentException("Please verify your official email with OTP before confirmation.");
        }
        if (repo.existsByEmailIgnoreCase(email) || exhibitorRepo.existsByEmailIgnoreCase(email)) {
            throw new DuplicateEmailException("This email is already registered.");
        }
        if (repo.existsByPhoneNormalized(phone) || exhibitorRepo.existsByPhoneNormalized(phone)) {
            throw new DuplicatePhoneException("This mobile number is already registered.");
        }

        TecverseRegistration registration = new TecverseRegistration();
        registration.setCompanyName(request.getCompanyName());
        registration.setWebsite(request.getWebsite());
        registration.setIndustry(request.getIndustry());
        registration.setCity(request.getCity());
        registration.setCountry(request.getCountry());
        registration.setGstNumber(request.getGst());
        registration.setCompanySize(request.getCompanySize() == null ? "Not specified" : request.getCompanySize());
        registration.setFullName(request.getFullName());
        registration.setEmail(email);
        registration.setPhone(phone);
        registration.setDesignation(request.getDesignation());
        registration.setLinkedinProfile(request.getLinkedin());
        registration.setStallPackage(request.getStallPackage());
        registration.setTechnologyArea(request.getTechnologyArea() == null ? "General Technology" : request.getTechnologyArea());
        registration.setPowerRequirement(request.getPowerRequirement() == null ? "As requested" : request.getPowerRequirement());
        registration.setProductsServices(request.getProducts());
        registration.setSpecialRequirements(request.getSpecialRequirements());
        registration.setRemarks(request.getRemarks());
        String referenceNumber = referenceService.nextExhibitorReference();
        registration.setReferenceNumber(referenceNumber);
        registration.setEmailVerified(true);
        registration.setCompanyLogoUrl(request.getCompanyLogoUrl());

        try {
            registration.setDocumentUrls(json.writeValueAsString(request.getDocumentUrls()));
            registration.setSubmissionDetails(json.writeValueAsString(request));
        } catch (Exception ex) {
            throw new IllegalStateException("Could not serialize registration details", ex);
        }

        registration = repo.saveAndFlush(registration);
        saveExhibitor(request, referenceNumber);
        otp.consume(email);
        eventPublisher.publishEvent(new ExhibitorRegistrationSavedEvent(
                registration.getEmail(), registration.getFullName(), registration.getReferenceNumber(),
                registration.getCompanyName(), registration.getStallPackage()));
        return toResponse(registration);
    }

    private void saveExhibitor(RegistrationRequest request, String referenceNumber) {
        Exhibitor exhibitor = new Exhibitor();
        exhibitor.setReferenceNumber(referenceNumber);
        exhibitor.setCompanyName(request.getCompanyName());
        exhibitor.setIndustry(request.getIndustry());
        exhibitor.setWebsite(request.getWebsite());
        exhibitor.setCompanyAddress(request.getCompanyAddress());
        exhibitor.setCity(request.getCity());
        exhibitor.setState(request.getState());
        exhibitor.setCountry(request.getCountry());
        exhibitor.setGst(request.getGst());
        exhibitor.setCompanyRegistrationNumber(request.getCompanyRegistrationNumber());
        exhibitor.setLinkedin(request.getLinkedin());
        exhibitor.setCompanyDescription(request.getCompanyDescription());
        exhibitor.setProductServiceCategory(request.getProductServiceCategory());
        exhibitor.setFullName(request.getFullName());
        exhibitor.setDesignation(request.getDesignation());
        exhibitor.setPhone(ValidationUtil.normalizeIndianMobile(request.getPhone()));
        exhibitor.setWhatsappNumber(request.getWhatsappNumber());
        exhibitor.setEmail(request.getEmail().trim().toLowerCase());
        exhibitor.setAlternateContactPerson(request.getAlternateContactPerson());
        exhibitor.setAlternateMobileNumber(request.getAlternateMobileNumber());
        exhibitor.setProducts(request.getProducts());
        exhibitor.setProductTechnologyName(request.getProductTechnologyName());
        exhibitor.setProductCategory(request.getProductCategory());
        exhibitor.setProductDescription(request.getProductDescription());
        exhibitor.setProductStage(request.getProductStage());
        exhibitor.setSpecialRequirements(request.getSpecialRequirements());
        exhibitor.setMachineryEquipment(request.getMachineryEquipment());
        exhibitor.setEquipmentDimensions(request.getEquipmentDimensions());
        exhibitor.setEquipmentWeight(request.getEquipmentWeight());
        exhibitor.setUtilityRequirements(request.getUtilityRequirements());
        exhibitor.setEquipmentImpact(request.getEquipmentImpact());
        exhibitor.setStallPackage(request.getStallPackage());
        exhibitor.setPowerRequirement(request.getPowerRequirement());
        exhibitor.setTechnologyArea(request.getTechnologyArea());
        exhibitor.setCompanySize(request.getCompanySize());
        exhibitor.setRemarks(request.getRemarks());
        exhibitor.setCompanyLogoPath(request.getCompanyLogoUrl());
        if (request.getDocumentUrls() != null && !request.getDocumentUrls().isEmpty()) {
            exhibitor.setDocumentOnePath(request.getDocumentUrls().get(0));
        }
        if (request.getDocumentUrls() != null && request.getDocumentUrls().size() > 1) {
            exhibitor.setDocumentTwoPath(request.getDocumentUrls().get(1));
        }
        try {
            exhibitor.setDocumentUrls(json.writeValueAsString(request.getDocumentUrls()));
        } catch (Exception ex) {
            throw new IllegalStateException("Could not serialize uploaded document paths", ex);
        }
        exhibitor.setEmailVerified(true);
        LocalDateTime now = LocalDateTime.now();
        exhibitor.setCreatedAt(now);
        exhibitor.setUpdatedAt(now);
        exhibitorRepo.saveAndFlush(exhibitor);
    }

    @Override
    public boolean checkEmailExists(String email) {
        if (email == null || email.isBlank()) return false;
        String normalizedEmail = email.trim().toLowerCase();
        return repo.existsByEmailIgnoreCase(normalizedEmail) || exhibitorRepo.existsByEmailIgnoreCase(normalizedEmail);
    }

    @Override
    public boolean checkPhoneExists(String phone) {
        if (phone == null || phone.isBlank()) return false;
        String normalizedPhone = ValidationUtil.normalizeIndianMobile(phone);
        return repo.existsByPhoneNormalized(normalizedPhone) || exhibitorRepo.existsByPhoneNormalized(normalizedPhone);
    }

    private RegistrationResponse toResponse(TecverseRegistration registration) {
        return RegistrationResponse.builder()
                .id(registration.getId())
                .companyName(registration.getCompanyName())
                .email(registration.getEmail())
                .phone(registration.getPhone())
                .stallPackage(registration.getStallPackage())
                .referenceNumber(registration.getReferenceNumber())
                .createdAt(registration.getCreatedAt())
                .build();
    }

}
