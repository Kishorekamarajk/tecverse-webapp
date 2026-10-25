package com.tecverse.app.controller;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice(basePackages = "com.tecverse.app.controller")
public class AdminViewModeAdvice {

    @ModelAttribute("adminReadOnly")
    public boolean adminReadOnly() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.isAuthenticated()
                && authentication.getAuthorities().stream()
                        .anyMatch(authority -> "ROLE_ADMIN_VIEWER".equals(authority.getAuthority()))
                && authentication.getAuthorities().stream()
                        .noneMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()));
    }
}
