package com.tecverse.app.controller;

import com.tecverse.app.service.AdminIdCardPdfService;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Controller
public class AdminIdCardController {
    private static final long MAX_PHOTO_BYTES = 1024L * 1024L;
    private final AdminIdCardPdfService pdfService;

    public AdminIdCardController(AdminIdCardPdfService pdfService) {
        this.pdfService = pdfService;
    }

    @GetMapping("/admin/id-cards")
    public String idCards() {
        return "admin/id-cards";
    }

    @PostMapping(value = "/admin/id-cards/generate", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Object generate(@RequestParam String name,
                           @RequestParam String designation,
                           @RequestParam String organization,
                           @RequestParam String category,
                           @RequestParam(defaultValue = "generate") String action,
                           @RequestParam(value = "photo", required = false) MultipartFile photo,
                           Model model,
                           RedirectAttributes redirectAttributes) throws IOException {
        String safeName = clean(name);
        String safeDesignation = clean(designation);
        String safeOrganization = clean(organization);
        String safeCategory = clean(category).toUpperCase(Locale.ROOT);
        if (safeName.isEmpty() || safeName.length() > 150
                || safeDesignation.isEmpty() || safeDesignation.length() > 150
                || safeOrganization.isEmpty() || safeOrganization.length() > 200
                || !safeCategory.matches("SPEAKER|ORGANIZER|VIP")) {
            model.addAttribute("errorMessage", "Enter a valid name, designation, organization, and card category.");
            model.addAttribute("name", name);
            model.addAttribute("designation", designation);
            model.addAttribute("organization", organization);
            model.addAttribute("category", category);
            return "admin/id-cards";
        }
        byte[] photoBytes = null;
        if (photo != null && !photo.isEmpty()) {
            if (photo.getSize() > MAX_PHOTO_BYTES) {
                model.addAttribute("errorMessage", "Photo must be 1 MB or smaller.");
                model.addAttribute("name", safeName);
                model.addAttribute("designation", safeDesignation);
                model.addAttribute("organization", safeOrganization);
                model.addAttribute("category", safeCategory);
                return "admin/id-cards";
            }
            String contentType = photo.getContentType();
            if (contentType == null || !contentType.toLowerCase(Locale.ROOT).matches("image/(png|jpeg)")) {
                model.addAttribute("errorMessage", "Upload a JPG or PNG photo.");
                model.addAttribute("name", safeName);
                model.addAttribute("designation", safeDesignation);
                model.addAttribute("organization", safeOrganization);
                model.addAttribute("category", safeCategory);
                return "admin/id-cards";
            }
            photoBytes = photo.getBytes();
        }

        AdminIdCardPdfService.GeneratedCard card;
        try {
            card = pdfService.generate(safeName, safeDesignation, safeOrganization, safeCategory, photoBytes);
        } catch (IllegalArgumentException exception) {
            model.addAttribute("errorMessage", exception.getMessage());
            model.addAttribute("name", safeName);
            model.addAttribute("designation", safeDesignation);
            model.addAttribute("organization", safeOrganization);
            model.addAttribute("category", safeCategory);
            return "admin/id-cards";
        }
        if ("save".equalsIgnoreCase(action)) {
            redirectAttributes.addFlashAttribute("successMessage", "ID card details saved successfully. Reference: " + card.reference());
            return "redirect:/admin/id-cards";
        }
        String filename = "tecverse-id-card-" + card.reference().toLowerCase(Locale.ROOT) + ".pdf";
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename(filename, StandardCharsets.UTF_8).build().toString())
                .header("X-Content-Type-Options", "nosniff")
                .body(card.pdf());
    }

    private static String clean(String value) {
        return StringUtils.hasText(value) ? value.trim() : "";
    }
}
