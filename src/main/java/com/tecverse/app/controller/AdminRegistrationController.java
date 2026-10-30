package com.tecverse.app.controller;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.tecverse.app.entity.ContactUs;
import com.tecverse.app.entity.Exhibitor;
import com.tecverse.app.entity.SponsorEnquiry;
import com.tecverse.app.entity.TicketRegistration;
import com.tecverse.app.repository.ContactUsRepository;
import com.tecverse.app.repository.ExhibitorRepository;
import com.tecverse.app.repository.SponsorEnquiryRepository;
import com.tecverse.app.repository.TicketRegistrationRepository;
import com.tecverse.app.repository.TecverseRegistrationRepository;
import com.tecverse.app.repository.MobileAttendeePreferenceRepository;
import com.tecverse.app.repository.MobileNotificationRepository;
import com.tecverse.app.repository.MobilePassCheckInRepository;

@Controller
public class AdminRegistrationController {
    private final TicketRegistrationRepository tickets;
    private final ExhibitorRepository exhibitors;
    private final SponsorEnquiryRepository sponsors;
    private final ContactUsRepository contacts;
    private final MobileAttendeePreferenceRepository attendeePreferences;
    private final MobileNotificationRepository mobileNotifications;
    private final MobilePassCheckInRepository passCheckIns;
    private final TecverseRegistrationRepository exhibitorRegistrationMirrors;

    public AdminRegistrationController(TicketRegistrationRepository tickets, ExhibitorRepository exhibitors,
            SponsorEnquiryRepository sponsors, ContactUsRepository contacts,
            MobileAttendeePreferenceRepository attendeePreferences,
            MobileNotificationRepository mobileNotifications, MobilePassCheckInRepository passCheckIns,
            TecverseRegistrationRepository exhibitorRegistrationMirrors) {
        this.tickets = tickets;
        this.exhibitors = exhibitors;
        this.sponsors = sponsors;
        this.contacts = contacts;
        this.attendeePreferences = attendeePreferences;
        this.mobileNotifications = mobileNotifications;
        this.passCheckIns = passCheckIns;
        this.exhibitorRegistrationMirrors = exhibitorRegistrationMirrors;
    }

    @GetMapping("/admin/registrations/{type}")
    public String list(@PathVariable String type, Model model) {
        List<RecordRow> rows = new ArrayList<>();
        switch (type) {
            case "tickets" -> tickets.findAll().forEach(x -> rows.add(new RecordRow(x.getId(), x.getReferenceNumber(), x.getOfficialName(), x.getEmail(), x.getPhone(), x.getCategory(), x.getApplicantState(), x.getCreatedAt())));
            case "exhibitors" -> exhibitors.findAll().forEach(x -> rows.add(new RecordRow(x.getId(), x.getReferenceNumber(), x.getFullName(), x.getEmail(), x.getPhone(), x.getCompanyName(), "", x.getCreatedAt())));
            case "sponsors" -> sponsors.findAll().forEach(x -> rows.add(new RecordRow(x.getId(), x.getId().toString(), x.getName(), x.getEmail(), x.getPhone(), x.getStatus(), "", x.getCreatedAt())));
            case "contacts" -> contacts.findAll().forEach(x -> rows.add(new RecordRow(x.getId(), x.getId().toString(), x.getFullName(), x.getEmail(), x.getPhoneNumber(), x.getCompanyName(), "", x.getCreatedAt())));
            default -> throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        model.addAttribute("type", type);
        model.addAttribute("title", title(type));
        model.addAttribute("rows", rows);
        return "admin/registrations";
    }

    @GetMapping("/admin/registrations/{type}/fragment")
    public String fragment(@PathVariable String type, @RequestParam(defaultValue = "0") int page, Model model) {
        int pageNumber = Math.max(0, page);
        Pageable pageable = PageRequest.of(pageNumber, 10, Sort.by(Sort.Direction.DESC, "createdAt").and(Sort.by(Sort.Direction.DESC, "id")));
        Page<RecordRow> result;
        switch (type) {
            case "tickets" -> result = tickets.findAll(pageable).map(x -> new RecordRow(x.getId(), x.getReferenceNumber(), x.getOfficialName(), x.getEmail(), x.getPhone(), x.getCategory(), x.getApplicantState(), x.getCreatedAt()));
            case "exhibitors" -> result = exhibitors.findAll(pageable).map(x -> new RecordRow(x.getId(), x.getReferenceNumber(), x.getFullName(), x.getEmail(), x.getPhone(), x.getCompanyName(), "", x.getCreatedAt()));
            case "sponsors" -> result = sponsors.findAll(pageable).map(x -> new RecordRow(x.getId(), x.getId().toString(), x.getName(), x.getEmail(), x.getPhone(), x.getStatus(), "", x.getCreatedAt()));
            case "contacts" -> result = contacts.findAll(pageable).map(x -> new RecordRow(x.getId(), x.getId().toString(), x.getFullName(), x.getEmail(), x.getPhoneNumber(), x.getCompanyName(), "", x.getCreatedAt()));
            default -> throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        model.addAttribute("type", type);
        model.addAttribute("rows", result.getContent());
        model.addAttribute("page", result);
        return "admin/fragments/registration-rows :: rows";
    }

    @GetMapping("/admin/registrations/{type}/{id}/edit")
    public String edit(@PathVariable String type, @PathVariable Long id, Model model) {
        Map<String, String> fields = readFields(type, id);
        model.addAttribute("type", type);
        model.addAttribute("id", id);
        model.addAttribute("title", title(type));
        model.addAttribute("fields", fields.entrySet().stream().map(e -> new Field(e.getKey(), label(e.getKey()), e.getValue())).toList());
        return "admin/registration-edit";
    }

    @PostMapping("/admin/registrations/{type}/{id}")
    public String save(@PathVariable String type, @PathVariable Long id, @RequestParam Map<String, String> form,
            RedirectAttributes redirect) {
        Map<String, String> allowed = readFields(type, id);
        for (String key : allowed.keySet()) {
            if (!form.containsKey(key)) continue;
            String value = form.get(key).trim();
            switch (type) {
                case "tickets" -> updateTicket(id, key, value);
                case "exhibitors" -> updateExhibitor(id, key, value);
                case "sponsors" -> updateSponsor(id, key, value);
                case "contacts" -> updateContact(id, key, value);
                default -> throw new ResponseStatusException(HttpStatus.NOT_FOUND);
            }
        }
        redirect.addFlashAttribute("successMessage", "Registration details updated.");
        return "redirect:/admin/registrations/" + type;
    }

    @PostMapping("/admin/registrations/{type}/{id}/delete")
    @Transactional
    public String delete(@PathVariable String type, @PathVariable Long id, RedirectAttributes redirect) {
        switch (type) {
            case "tickets" -> {
                if (!tickets.existsById(id)) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
                attendeePreferences.deleteByRegistrationId(id);
                mobileNotifications.deleteByRegistrationId(id);
                passCheckIns.deleteByRegistrationId(id);
                tickets.deleteById(id);
            }
            case "exhibitors" -> {
                Exhibitor exhibitor = exhibitors.findById(id)
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
                // Exhibitor submissions are mirrored in tecverse_registrations.
                // Delete both records in one transaction so the phone/email is freed.
                exhibitorRegistrationMirrors.findByReferenceNumber(exhibitor.getReferenceNumber())
                        .ifPresent(exhibitorRegistrationMirrors::delete);
                exhibitors.deleteById(id);
            }
            case "sponsors" -> {
                if (!sponsors.existsById(id)) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
                sponsors.deleteById(id);
            }
            case "contacts" -> {
                if (!contacts.existsById(id)) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
                contacts.deleteById(id);
            }
            default -> throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        redirect.addFlashAttribute("successMessage", "Registration record deleted successfully.");
        return "redirect:/admin/registrations/" + type;
    }

    private Map<String, String> readFields(String type, Long id) {
        Map<String, String> result = new LinkedHashMap<>();
        switch (type) {
            case "tickets" -> { TicketRegistration x = tickets.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)); put(result, "officialName", x.getOfficialName()); put(result, "email", x.getEmail()); put(result, "phone", x.getPhone()); put(result, "category", x.getCategory()); put(result, "applicantState", x.getApplicantState()); put(result, "attendanceDays", x.getAttendanceDays()); }
            case "exhibitors" -> { Exhibitor x = exhibitors.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)); put(result, "companyName", x.getCompanyName()); put(result, "fullName", x.getFullName()); put(result, "email", x.getEmail()); put(result, "phone", x.getPhone()); put(result, "designation", x.getDesignation()); put(result, "stallPackage", x.getStallPackage()); put(result, "remarks", x.getRemarks()); }
            case "sponsors" -> { SponsorEnquiry x = sponsors.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)); put(result, "company", x.getCompany()); put(result, "name", x.getName()); put(result, "email", x.getEmail()); put(result, "phone", x.getPhone()); put(result, "sponsorshipInterest", x.getSponsorshipInterest()); put(result, "status", x.getStatus()); put(result, "paymentStatus", x.getPaymentStatus()); put(result, "message", x.getMessage()); }
            case "contacts" -> { ContactUs x = contacts.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)); put(result, "fullName", x.getFullName()); put(result, "email", x.getEmail()); put(result, "phoneNumber", x.getPhoneNumber()); put(result, "companyName", x.getCompanyName()); put(result, "jobTitle", x.getJobTitle()); put(result, "country", x.getCountry()); put(result, "message", x.getMessage()); }
            default -> throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        return result;
    }

    private void updateTicket(Long id, String key, String v) { TicketRegistration x = tickets.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)); switch (key) { case "officialName" -> x.setOfficialName(v); case "email" -> x.setEmail(v); case "phone" -> x.setPhone(v); case "category" -> x.setCategory(v); case "applicantState" -> x.setApplicantState(v); case "attendanceDays" -> x.setAttendanceDays(v); } tickets.save(x); }
    private void updateExhibitor(Long id, String key, String v) { Exhibitor x = exhibitors.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)); switch (key) { case "companyName" -> x.setCompanyName(v); case "fullName" -> x.setFullName(v); case "email" -> x.setEmail(v); case "phone" -> x.setPhone(v); case "designation" -> x.setDesignation(v); case "stallPackage" -> x.setStallPackage(v); case "remarks" -> x.setRemarks(v); } exhibitors.save(x); }
    private void updateSponsor(Long id, String key, String v) { SponsorEnquiry x = sponsors.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)); switch (key) { case "company" -> x.setCompany(v); case "name" -> x.setName(v); case "email" -> x.setEmail(v); case "phone" -> x.setPhone(v); case "sponsorshipInterest" -> x.setSponsorshipInterest(v); case "status" -> x.setStatus(v); case "paymentStatus" -> x.setPaymentStatus(v); case "message" -> x.setMessage(v); } sponsors.save(x); }
    private void updateContact(Long id, String key, String v) { ContactUs x = contacts.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)); switch (key) { case "fullName" -> x.setFullName(v); case "email" -> x.setEmail(v); case "phoneNumber" -> x.setPhoneNumber(v); case "companyName" -> x.setCompanyName(v); case "jobTitle" -> x.setJobTitle(v); case "country" -> x.setCountry(v); case "message" -> x.setMessage(v); } contacts.save(x); }
    private static void put(Map<String, String> fields, String key, String value) { fields.put(key, value == null ? "" : value); }
    private static String title(String type) { return switch (type) { case "tickets" -> "Attendee registrations"; case "exhibitors" -> "Exhibitors"; case "sponsors" -> "Sponsor enquiries"; case "contacts" -> "Contact enquiries"; default -> throw new ResponseStatusException(HttpStatus.NOT_FOUND); }; }
    private static String label(String key) { return switch (key) { case "officialName" -> "Full name"; case "applicantState" -> "State / Union Territory"; case "attendanceDays" -> "Attendance days"; case "companyName" -> "Company"; case "fullName" -> "Contact name"; case "stallPackage" -> "Stall package"; case "sponsorshipInterest" -> "Sponsorship interest"; case "paymentStatus" -> "Payment status"; case "phoneNumber" -> "Phone"; case "jobTitle" -> "Job title"; default -> Character.toUpperCase(key.charAt(0)) + key.substring(1); }; }
    public record RecordRow(Long id, String reference, String name, String email, String phone, String detail, String applicantState, java.time.LocalDateTime createdAt) {}
    public record Field(String key, String label, String value) {}
}
