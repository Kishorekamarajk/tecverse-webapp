package com.tecverse.app.service.impl;

import com.tecverse.app.dto.TicketRegistrationRequest;
import com.tecverse.app.dto.TicketRegistrationResponse;
import com.tecverse.app.entity.TicketRegistration;
import com.tecverse.app.repository.TicketRegistrationRepository;
import com.tecverse.app.service.TicketRegistrationService;
import com.tecverse.app.service.TicketOtpService;
import com.tecverse.app.service.QRCodeGeneratorService;
import com.tecverse.app.event.TicketRegistrationSavedEvent;
import org.springframework.context.ApplicationEventPublisher;
import com.tecverse.app.util.ValidationUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

import jakarta.mail.MessagingException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import java.util.List;
import java.util.Comparator;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TicketRegistrationServiceImpl implements TicketRegistrationService {
    private static final Logger log = LoggerFactory.getLogger(TicketRegistrationServiceImpl.class);
    private static final int MAX_CONFIRMATION_EMAIL_ATTEMPTS = 5;
    private final TicketRegistrationRepository repo;
    private final JavaMailSender mailSender;
    private final TicketOtpService otpService;
    private final String fromAddress;
    private final PasswordEncoder passwordEncoder;
    private final com.tecverse.app.service.TicketRegistrationReferenceService referenceService;
    private final ApplicationEventPublisher eventPublisher;
    private final Validator validator;
    private final QRCodeGeneratorService qrCodeGeneratorService;
    private final String appUrl;
    private final TransactionTemplate transactionTemplate;

    public TicketRegistrationServiceImpl(TicketRegistrationRepository repo, JavaMailSender mailSender, TicketOtpService otpService, PasswordEncoder passwordEncoder,
                                         com.tecverse.app.service.TicketRegistrationReferenceService referenceService,
                                         ApplicationEventPublisher eventPublisher,
                                         Validator validator,
                                         QRCodeGeneratorService qrCodeGeneratorService,
                                         PlatformTransactionManager transactionManager,
                                         @Value("${spring.mail.username:}") String fromAddress,
                                         @Value("${app.url:http://localhost:8080}") String appUrl) {
        this.repo=repo; this.mailSender=mailSender; this.otpService=otpService; this.passwordEncoder=passwordEncoder; this.referenceService=referenceService; this.eventPublisher=eventPublisher; this.validator=validator; this.fromAddress=fromAddress;
        this.qrCodeGeneratorService=qrCodeGeneratorService; this.appUrl=appUrl;
        this.transactionTemplate=new TransactionTemplate(transactionManager);
    }

    @Transactional
    public TicketRegistrationResponse register(TicketRegistrationRequest r) {
        validateRequest(r);
        String email=normEmail(r.getEmail()), phone=ValidationUtil.normalizeIndianMobile(r.getPhone());
        if (!r.getPassword().equals(r.getConfirmPassword())) throw new IllegalArgumentException("Password and confirm password must match.");
        validateCategoryDetails(r);
        if(!otpService.isEmailVerified(email)) throw new IllegalArgumentException("Please verify your email with OTP before submitting the registration.");
        if(!repo.existsByEmailOrPhone(email, phone)) {
            String ref=referenceService.nextReference(r);
            TicketRegistration e=new TicketRegistration();
            e.setReferenceNumber(ref); e.setScanToken(UUID.randomUUID().toString().replace("-", ""));
            e.setOfficialName(clean(r.getOfficialName())); e.setEmail(email); e.setPhone(phone);
            e.setPasswordHash(passwordEncoder.encode(r.getPassword()));
            e.setCategory(clean(r.getCategory())); e.setAcademiaType(clean(r.getAcademiaType()));
            e.setCollegeName(clean(r.getCollegeName())); e.setCollegeDistrict(clean(r.getCollegeDistrict())); e.setCollegeState(clean(r.getCollegeState()));
            e.setUniversityName(clean(r.getUniversityName())); e.setAcademiaRole(clean(r.getAcademiaRole())); e.setRegisterNumber(clean(r.getRegisterNumber()));
            e.setCentralMinistry(clean(r.getCentralMinistry())); e.setStateName(clean(r.getStateName())); e.setStateDepartment(clean(r.getStateDepartment()));
            e.setOrganizationName(clean(r.getOrganizationName())); e.setOrganizationLocation(clean(r.getOrganizationLocation()));
            e.setDesignation(clean(r.getDesignation())); e.setIndustryOrStartup(clean(r.getIndustryOrStartup()));
            e.setCitizenshipStatus(clean(r.getCitizenshipStatus())); e.setPassportNumber(clean(r.getPassportNumber()));
            e.setApplicantState(clean(r.getApplicantState()));
            e.setPassportValidUntil(clean(r.getPassportValidUntil())); e.setPassportName(clean(r.getPassportName()));
            e.setAttendanceDays(r.getAttendanceDays()==null?"":r.getAttendanceDays().stream().map(this::clean).collect(Collectors.joining(",")));
            e.setConfirmationEmailSent(false);
            // Force the insert now so a success response is only returned after the row is in the database.
            repo.saveAndFlush(e);
            eventPublisher.publishEvent(new TicketRegistrationSavedEvent(e.getId()));
            if (otpService instanceof com.tecverse.app.service.impl.TicketOtpServiceImpl impl) impl.consumeEmailVerification(email);
            return new TicketRegistrationResponse(ref,email,"Registration saved; confirmation email will be sent shortly.",false,e.getScanToken());
        }
        if(repo.existsByEmail(email)) throw new IllegalArgumentException("This email is already registered.");
        throw new IllegalArgumentException("This phone number is already registered.");
    }

    private void validateRequest(TicketRegistrationRequest request) {
        List<String> errors = validator.validate(request).stream()
                .sorted(Comparator.comparing(v -> v.getPropertyPath().toString()))
                .map(ConstraintViolation::getMessage)
                .toList();
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException(String.join(" ", errors));
        }
    }

    private void validateCategoryDetails(TicketRegistrationRequest r) {
        switch (r.getCategory()) {
            case "ACADEMIA" -> {
                require(r.getAcademiaRole(), "Select an applicant role.", r.getCollegeName(), "College / institution name is required.", r.getCollegeDistrict(), "College district is required.", r.getCollegeState(), "College state is required.", r.getUniversityName(), "University is required.");
                switch (r.getAcademiaRole().trim().toUpperCase(java.util.Locale.ROOT)) {
                    case "STUDENT" -> require(r.getRegisterNumber(), "Student ID number is required.");
                    case "FACULTY", "PROFESSOR / FACULTY", "PROFESSOR/FACULTY", "RESEARCH SCHOLAR" -> { }
                    default -> throw new IllegalArgumentException("Choose a valid Academia applicant role.");
                }
            }
            case "CENTRAL_GOVERNMENT" -> require(r.getCentralMinistry(), "Select a central ministry.", r.getOrganizationName(), "Organization name is required.", r.getDesignation(), "Designation is required.", r.getOrganizationLocation(), "Organization location is required.");
            case "STATE_GOVERNMENT" -> require(r.getStateName(), "Select a state.", r.getStateDepartment(), "Select a state department.", r.getOrganizationName(), "Organization name is required.", r.getDesignation(), "Designation is required.", r.getOrganizationLocation(), "Organization location is required.");
            case "INDUSTRY_STARTUP" -> require(r.getIndustryOrStartup(), "Select Industry or Startup.", r.getOrganizationName(), "Company name is required.", r.getOrganizationLocation(), "Company location is required.", r.getDesignation(), "Designation is required.");
            case "VIP_SPECIAL_INVITEE", "SPEAKER", "ORGANIZER" -> { }
            default -> throw new IllegalArgumentException("Choose a valid registration category.");
        }
        if ("FOREIGNER".equals(r.getCitizenshipStatus())) {
            require(r.getPassportNumber(), "Passport number is required.", r.getPassportValidUntil(), "Passport validity date is required.", r.getPassportName(), "Name as shown on passport is required.");
        }
        if (r.getAttendanceDays() == null || r.getAttendanceDays().isEmpty()) throw new IllegalArgumentException("Select at least one attendance day.");
        if (r.getAttendanceDays().size() > 1 && r.getAttendanceDays().contains("BOTH")) throw new IllegalArgumentException("Choose Both days or individual days, not both.");
    }

    private void require(String... valuesAndMessages) {
        for (int i = 0; i < valuesAndMessages.length; i += 2) {
            if (valuesAndMessages[i] == null || valuesAndMessages[i].isBlank()) throw new IllegalArgumentException(valuesAndMessages[i + 1]);
        }
    }

    private boolean attemptConfirmation(TicketRegistration registration) {
        registration.setConfirmationEmailAttempts(registration.getConfirmationEmailAttempts() + 1);
        boolean sent = sendConfirmation(registration);
        registration.setConfirmationEmailSent(sent);
        repo.save(registration);
        return sent;
    }

    @Override
    public void sendConfirmationForRegistration(Long registrationId) {
        transactionTemplate.executeWithoutResult(status -> repo.findByIdForUpdate(registrationId).ifPresent(registration -> {
            if (!registration.isConfirmationEmailSent() && registration.getConfirmationEmailAttempts() < MAX_CONFIRMATION_EMAIL_ATTEMPTS) {
                attemptConfirmation(registration);
            }
        }));
    }

    @Scheduled(fixedDelayString = "${tecverse.mail.confirmation-retry-ms:300000}",
            initialDelayString = "${tecverse.mail.confirmation-retry-initial-ms:60000}")
    public void retryPendingConfirmationEmails() {
        List<TicketRegistration> pending = repo
                .findTop25ByConfirmationEmailSentFalseAndConfirmationEmailAttemptsLessThanOrderByCreatedAtAsc(
                        MAX_CONFIRMATION_EMAIL_ATTEMPTS);
        for (TicketRegistration registration : pending) sendConfirmationForRegistration(registration.getId());
    }

    private boolean sendConfirmation(TicketRegistration e){
        try {
            String scanUrl=appUrl.replaceAll("/+$", "")+"/ticket/scan/"+e.getScanToken();
            byte[] qrPng=qrCodeGeneratorService.generateQRCodeImageBytes(scanUrl,360,360);
            var msg=mailSender.createMimeMessage();
            // Two body variants (plain text and HTML) require multipart alternative mode.
            var helper=new MimeMessageHelper(msg,true,"UTF-8");
            if(fromAddress!=null&&!fromAddress.isBlank()) helper.setFrom(fromAddress);
            helper.setTo(e.getEmail());
            helper.setSubject("Registration Confirmed | Tec-Verse 2026 — Your Official Entry Pass");
            ClassPathResource logo=new ClassPathResource("static/images/tecverselogo.png");
            boolean hasLogo=logo.exists();
            helper.setText(confirmationText(e), confirmationHtml(e,hasLogo));
            helper.addInline("participantQr",new ByteArrayResource(qrPng),"image/png");
            if(hasLogo)helper.addInline("tecVerseLogo",logo,"image/png");
            mailSender.send(msg);
            log.info("Ticket confirmation email accepted by SMTP for registration {}.", e.getReferenceNumber());
            return true;
        } catch(MessagingException | MailException | java.io.IOException | IllegalArgumentException ex) {
            log.warn("Ticket registration {} confirmation email attempt {} failed; it remains queued for retry when available (maximum {} attempts).",
                    e.getReferenceNumber(), e.getConfirmationEmailAttempts(), MAX_CONFIRMATION_EMAIL_ATTEMPTS, ex);
            return false;
        }
    }
    private String confirmationHtml(TicketRegistration e,boolean hasLogo) {
        String designation=firstNonBlank(e.getDesignation(),e.getAcademiaRole());
        String organization=firstNonBlank(e.getOrganizationName(),e.getCollegeName(),e.getUniversityName(),e.getAcademiaType());
        String logo=hasLogo?"<img src=\"cid:tecVerseLogo\" width=\"54\" height=\"54\" alt=\"Tec-Verse logo\" style=\"display:block;width:54px;height:54px;object-fit:contain;border:0;\">":"<span style=\"font-size:22px;font-weight:800;letter-spacing:2px;color:#ffffff;\">TEC-VERSE</span>";
        return "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><style>"
                + "@media only screen and (max-width:620px){.email-shell{width:100%!important}.email-pad{padding-left:20px!important;padding-right:20px!important}.stack-column{display:block!important;width:100%!important;max-width:100%!important}.pass-cell{padding:20px 0 0!important}}"
                + "</style></head><body style=\"margin:0;padding:0;background:#f2f5fb;font-family:Arial,Helvetica,sans-serif;color:#17243b;\">"
                + "<table role=\"presentation\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" style=\"background:#f2f5fb;\"><tr><td align=\"center\" style=\"padding:28px 12px;\">"
                + "<table role=\"presentation\" class=\"email-shell\" width=\"680\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" style=\"width:100%;max-width:680px;background:#ffffff;border:1px solid #e2e8f2;border-radius:16px;overflow:hidden;\">"
                + "<tr><td align=\"center\" style=\"padding:24px 24px 22px;background-color:#182f70;background-image:linear-gradient(120deg,#10294f 0%,#2755a5 58%,#5936a7 100%);color:#ffffff;\">"
                + "<table role=\"presentation\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\"><tr><td align=\"center\">"+logo+"</td></tr><tr><td align=\"center\" style=\"padding-top:10px;font-size:20px;font-weight:800;letter-spacing:2px;color:#ffffff;\">TEC-VERSE 2026</td></tr>"
                + "<tr><td align=\"center\" style=\"padding-top:6px;font-size:13px;letter-spacing:.4px;color:#e0e8ff;\">Connect. Collaborate.Innovate.</td></tr></table></td></tr>"
                + "<tr><td class=\"email-pad\" style=\"padding:30px 34px 12px;\"><h1 style=\"margin:0 0 17px;font-size:27px;line-height:1.25;color:#172e65;\">Registration Confirmed</h1>"
                + "<p style=\"margin:0 0 14px;font-size:15px;line-height:1.65;\">Dear "+escapeHtml(e.getOfficialName())+",</p>"
                + "<p style=\"margin:0 0 12px;font-size:15px;line-height:1.65;color:#4d5b73;\">We are pleased to confirm that your registration for Tec-Verse 2026 has been successfully completed.</p>"
                + "<p style=\"margin:0;font-size:15px;line-height:1.65;color:#4d5b73;\">Your registration details and personalized digital entry pass are provided below for your reference.</p></td></tr>"
                + "<tr><td class=\"email-pad\" style=\"padding:12px 34px 30px;\"><table role=\"presentation\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\"><tr>"
                + "<td class=\"stack-column\" width=\"56%\" valign=\"top\" style=\"width:56%;padding:20px;border:1px solid #e4eaf4;border-radius:12px;background:#fbfcff;\">"
                + "<h2 style=\"margin:0 0 13px;font-size:17px;color:#1b3473;\">Registration Details</h2>"
                + detailRow("Participant Name",e.getOfficialName())+detailRow("Designation",designation)+detailRow("Organization",organization)
                + detailRow("Registration Reference ID",e.getReferenceNumber())+detailRow("Event Dates","26–27 November 2026")+detailRow("Venue","Chennai Trade Centre, Chennai")
                + "</td><td class=\"stack-column pass-cell\" width=\"44%\" valign=\"top\" style=\"width:44%;padding-left:16px;\"><table role=\"presentation\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" style=\"border:1px solid #dfe6f4;border-radius:12px;background:#f7f8ff;\">"
                + "<tr><td align=\"center\" style=\"padding:20px 12px 8px;font-size:17px;font-weight:700;color:#243b7a;\">Your Digital Entry Pass</td></tr>"
                + "<tr><td align=\"center\" style=\"padding:7px 16px 10px;\"><img src=\"cid:participantQr\" width=\"210\" height=\"210\" alt=\"Your Tec-Verse 2026 registration QR code\" style=\"display:block;width:210px;height:210px;max-width:100%;border:0;background:#ffffff;\"></td></tr>"
                + "<tr><td align=\"center\" style=\"padding:0 12px 20px;font-size:13px;color:#586783;\">Reference ID<br><strong style=\"display:inline-block;padding-top:4px;font-size:15px;letter-spacing:.5px;color:#172e65;\">"+escapeHtml(e.getReferenceNumber())+"</strong></td></tr></table></td>"
                + "</tr></table></td></tr><tr><td class=\"email-pad\" style=\"padding:0 34px 26px;\"><p style=\"margin:0;padding:14px 16px;border-left:3px solid #4e63c7;background:#f4f6ff;font-size:14px;line-height:1.55;color:#35466a;\">Please retain this email and present your digital entry pass when required at the event venue.</p>"
                + "<p style=\"margin:22px 0 18px;font-size:14px;line-height:1.7;color:#4d5b73;\">We look forward to welcoming you to Tec-Verse 2026, where innovation, research, and emerging technologies converge to shape the future.</p>"
                + "<p style=\"margin:0;font-size:14px;line-height:1.7;color:#34445f;\">Warm regards,<br><strong>Tec-Verse 2026 Organising Team</strong><br>Connect. Collaborate.Innovate.<br>Central Government | CDAC</p></td></tr>"
                + "<tr><td align=\"center\" style=\"padding:17px 20px;background:#f7f8fc;border-top:1px solid #e8edf5;font-size:12px;color:#78849a;\">Tec-Verse 2026 · Chennai Trade Centre, Chennai</td></tr>"
                + "</table></td></tr></table></body></html>";
    }
    private String confirmationText(TicketRegistration e) {
        return "Dear " + safeText(e.getOfficialName()) + ",\n\n"
                + "We are pleased to confirm that your registration for Tec-Verse 2026 has been successfully completed.\n\n"
                + "Registration Details\n"
                + "Participant Name: " + safeText(e.getOfficialName()) + "\n"
                + "Designation: " + safeText(firstNonBlank(e.getDesignation(),e.getAcademiaRole())) + "\n"
                + "Organization: " + safeText(firstNonBlank(e.getOrganizationName(),e.getCollegeName(),e.getUniversityName(),e.getAcademiaType())) + "\n"
                + "Registration Reference ID: " + safeText(e.getReferenceNumber()) + "\n"
                + "Event Dates: 26-27 November 2026\nVenue: Chennai Trade Centre, Chennai\n\n"
                + "Please retain this email and present your digital entry pass when required at the event venue.\n\n"
                + "We look forward to welcoming you to Tec-Verse 2026, where innovation, research, and emerging technologies converge to shape the future.\n\n"
                + "Warm regards,\nTec-Verse 2026 Organising Team\nConnect. Collaborate.Innovate.\nCentral Government | CDAC";
    }
    private String detailRow(String label,String value) {
        return "<table role=\"presentation\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" style=\"border-bottom:1px solid #e8edf5;\"><tr><td style=\"padding:9px 0 3px;font-size:11px;text-transform:uppercase;letter-spacing:.55px;color:#77839a;\">"+escapeHtml(label)+"</td></tr><tr><td style=\"padding:0 0 9px;font-size:14px;line-height:1.4;font-weight:600;color:#26344c;overflow-wrap:anywhere;\">"+escapeHtml(value==null||value.isBlank()?"Not provided":value)+"</td></tr></table>";
    }
    private static String firstNonBlank(String... values) {
        for(String value:values)if(value!=null&&!value.isBlank())return value;
        return "Not provided";
    }
    private static String safeText(String value) { return value==null||value.isBlank()?"Not provided":value; }
    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
    private String normEmail(String v){return v==null?"":v.trim().toLowerCase();}
    private String clean(String v){return v==null||v.isBlank()?null:ValidationUtil.sanitize(v.trim());}
}
