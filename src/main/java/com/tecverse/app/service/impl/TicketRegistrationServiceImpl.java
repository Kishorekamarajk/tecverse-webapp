package com.tecverse.app.service.impl;

import com.tecverse.app.dto.TicketRegistrationRequest;
import com.tecverse.app.dto.TicketRegistrationResponse;
import com.tecverse.app.entity.TicketRegistration;
import com.tecverse.app.repository.TicketRegistrationRepository;
import com.tecverse.app.service.TicketRegistrationService;
import com.tecverse.app.service.TicketOtpService;
import com.tecverse.app.event.TicketRegistrationSavedEvent;
import org.springframework.context.ApplicationEventPublisher;
import com.tecverse.app.util.ValidationUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;

import jakarta.mail.MessagingException;
import java.util.List;
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

    public TicketRegistrationServiceImpl(TicketRegistrationRepository repo, JavaMailSender mailSender, TicketOtpService otpService, PasswordEncoder passwordEncoder,
                                         com.tecverse.app.service.TicketRegistrationReferenceService referenceService,
                                         ApplicationEventPublisher eventPublisher,
                                         @Value("${spring.mail.username:}") String fromAddress) {
        this.repo=repo; this.mailSender=mailSender; this.otpService=otpService; this.passwordEncoder=passwordEncoder; this.referenceService=referenceService; this.eventPublisher=eventPublisher; this.fromAddress=fromAddress;
    }

    @Transactional
    public TicketRegistrationResponse register(TicketRegistrationRequest r) {
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
    @Transactional
    public void sendConfirmationForRegistration(Long registrationId) {
        repo.findById(registrationId).ifPresent(registration -> {
            if (!registration.isConfirmationEmailSent()
                    && registration.getConfirmationEmailAttempts() < MAX_CONFIRMATION_EMAIL_ATTEMPTS) {
                attemptConfirmation(registration);
            }
        });
    }

    @Scheduled(fixedDelayString = "${tecverse.mail.confirmation-retry-ms:300000}",
            initialDelayString = "${tecverse.mail.confirmation-retry-initial-ms:60000}")
    public void retryPendingConfirmationEmails() {
        List<TicketRegistration> pending = repo
                .findTop25ByConfirmationEmailSentFalseAndConfirmationEmailAttemptsLessThanOrderByCreatedAtAsc(
                        MAX_CONFIRMATION_EMAIL_ATTEMPTS);
        for (TicketRegistration registration : pending) {
            attemptConfirmation(registration);
        }
    }

    private boolean sendConfirmation(TicketRegistration e){
        try {
            var msg=mailSender.createMimeMessage();
            // Two body variants (plain text and HTML) require multipart alternative mode.
            var helper=new MimeMessageHelper(msg,true,"UTF-8");
            if(fromAddress!=null&&!fromAddress.isBlank()) helper.setFrom(fromAddress);
            helper.setTo(e.getEmail());
            helper.setSubject("You're Registered! See You at Tec-Verse 2026!");
            helper.setText(confirmationText(e), confirmationHtml(e));
            mailSender.send(msg);
            log.info("Ticket confirmation email accepted by SMTP for registration {}.", e.getReferenceNumber());
            return true;
        } catch(MessagingException | MailException ex) {
            log.warn("Ticket registration {} confirmation email attempt {} failed; it remains queued for retry when available (maximum {} attempts).",
                    e.getReferenceNumber(), e.getConfirmationEmailAttempts(), MAX_CONFIRMATION_EMAIL_ATTEMPTS, ex);
            return false;
        }
    }
    private String confirmationHtml(TicketRegistration e) {
        return "<!doctype html><html><body style=\"margin:0;padding:0;background-color:#ffffff;font-family:Arial,Helvetica,sans-serif;color:#252b33;\">"
                + "<table role=\"presentation\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" style=\"background-color:#ffffff;\"><tr><td align=\"center\" style=\"padding:24px 16px;\">"
                + "<table role=\"presentation\" width=\"600\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" style=\"width:100%;max-width:600px;border:1px solid #e5e7eb;border-collapse:collapse;\">"
                + "<tr><td style=\"padding:28px 32px 8px;font-size:13px;font-weight:bold;letter-spacing:1px;color:#163b65;\">TEC-VERSE 2026</td></tr>"
                + "<tr><td style=\"padding:8px 32px 0;\"><h1 style=\"margin:0;font-size:24px;line-height:1.35;color:#163b65;font-weight:600;\">You're Registered! See You at Tec-Verse 2026!</h1></td></tr>"
                + "<tr><td style=\"padding:24px 32px 32px;font-size:15px;line-height:1.7;\">"
                + "<p style=\"margin:0 0 16px;\">Dear " + escapeHtml(e.getOfficialName()) + ",</p>"
                + "<p style=\"margin:0 0 16px;\">Your registration for Tec-Verse 2026 has been successfully confirmed.</p>"
                + "<p style=\"margin:0 0 22px;\">Get ready to explore groundbreaking technologies, connect with innovators, exchange ideas, and discover exciting collaboration opportunities!</p>"
                + "<p style=\"margin:0 0 6px;\"><strong>Dates:</strong> 26&ndash;27 November 2026</p>"
                + "<p style=\"margin:0 0 22px;\"><strong>Venue:</strong> Chennai Trade Centre, Chennai</p>"
                + "<p style=\"margin:0 0 18px;\">We can't wait to welcome you to Tec-Verse 2026.</p>"
                + "<p style=\"margin:0;\">Warm regards,<br>Tec-Verse 2026 Organising Team</p>"
                + "</td></tr></table></td></tr></table></body></html>";
    }
    private String confirmationText(TicketRegistration e) {
        return "Dear " + e.getOfficialName() + ",\n\n"
                + "Your registration for Tec-Verse 2026 has been successfully confirmed.\n"
                + "Get ready to explore groundbreaking technologies, connect with innovators, exchange ideas, and discover exciting collaboration opportunities!\n\n"
                + "Dates: 26-27 November 2026\n"
                + "Venue: Chennai Trade Centre, Chennai\n\n"
                + "We can't wait to welcome you to Tec-Verse 2026.\n\n"
                + "Warm regards,\nTec-Verse 2026 Organising Team";
    }
    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
    private String normEmail(String v){return v==null?"":v.trim().toLowerCase();}
    private String clean(String v){return v==null||v.isBlank()?null:ValidationUtil.sanitize(v.trim());}
}
