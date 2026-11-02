package com.tecverse.app.controller;

import jakarta.servlet.http.HttpServletRequest;
import com.tecverse.app.repository.ExhibitorRepository;
import com.tecverse.app.repository.SponsorEnquiryRepository;
import com.tecverse.app.util.ValidationUtil;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice
public class BusinessPortalModelAdvice {
    private final ExhibitorRepository exhibitors;
    private final SponsorEnquiryRepository sponsors;

    public BusinessPortalModelAdvice(ExhibitorRepository exhibitors, SponsorEnquiryRepository sponsors) {
        this.exhibitors = exhibitors;
        this.sponsors = sponsors;
    }

    @ModelAttribute
    public void addBusinessPortalState(
            HttpServletRequest request,
            Model model) {
        String path = request.getServletPath();
        if ("/profile".equals(path)) {
            var attendee = model.getAttribute("attendee");
            if (attendee instanceof com.tecverse.app.entity.TicketRegistration registration) {
                String phone = ValidationUtil.normalizeIndianMobile(registration.getPhone());
                if (phone != null && !phone.isBlank()) {
                    model.addAttribute("attendeeExhibitorRegistered", exhibitors.findLatestByPhoneNormalized(phone).isPresent());
                    model.addAttribute("attendeeSponsorRegistered", sponsors.findLatestByPhoneNormalized(phone).isPresent());
                }
            }
        }

        jakarta.servlet.http.HttpSession session = request.getSession(false);
        if (session == null) return;
        Object role = session.getAttribute("TECVERSE_BUSINESS_ROLE");
        Object phone = session.getAttribute("TECVERSE_BUSINESS_PHONE");
        if (("exhibitor".equals(role) || "sponsor".equals(role)) && phone instanceof String) {
            model.addAttribute("businessSignedIn", true);
            model.addAttribute("businessRole", role);
            model.addAttribute("businessContactName", session.getAttribute("TECVERSE_BUSINESS_NAME") instanceof String name ? name : "My account");
        }
    }
}
