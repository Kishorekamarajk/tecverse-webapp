package com.tecverse.app.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice
public class BusinessPortalModelAdvice {
    @ModelAttribute
    public void addBusinessPortalState(HttpServletRequest request, Model model) {
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
