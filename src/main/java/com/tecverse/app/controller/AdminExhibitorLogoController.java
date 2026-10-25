package com.tecverse.app.controller;

import com.tecverse.app.dto.ExhibitorLogoForm;
import com.tecverse.app.entity.ExhibitorLogo;
import com.tecverse.app.repository.ExhibitorLogoRepository;
import com.tecverse.app.service.GalleryStorageService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.ArrayList;
import java.util.List;

@Controller
public class AdminExhibitorLogoController {
    private final ExhibitorLogoRepository repository;
    private final GalleryStorageService storage;

    public AdminExhibitorLogoController(ExhibitorLogoRepository repository, GalleryStorageService storage) {
        this.repository = repository;
        this.storage = storage;
    }

    @GetMapping("/admin/exhibitor-logos")
    public String list(Model model) {
        model.addAttribute("exhibitorLogos", repository.findAllByOrderByDisplayOrderAscIdAsc());
        return "admin/exhibitor-logos";
    }

    @GetMapping("/admin/exhibitor-logos/new")
    public String newForm(Model model) {
        model.addAttribute("exhibitorLogoForm", new ExhibitorLogoForm());
        model.addAttribute("mode", "new");
        return "admin/exhibitor-logo-form";
    }

    @GetMapping("/admin/exhibitor-logos/{id}/edit")
    public String editForm(@PathVariable Long id, Model model) {
        ExhibitorLogo logo = get(id);
        model.addAttribute("exhibitorLogoForm", form(logo));
        model.addAttribute("logoId", id);
        model.addAttribute("mode", "edit");
        model.addAttribute("currentImageUrl", logo.getImageUrl());
        return "admin/exhibitor-logo-form";
    }

    @PostMapping("/admin/exhibitor-logos")
    public String create(@Valid @ModelAttribute("exhibitorLogoForm") ExhibitorLogoForm form,
                         BindingResult result,
                         @RequestParam(value = "imageFile", required = false) MultipartFile imageFile) {
        if (result.hasErrors()) return "admin/exhibitor-logo-form";
        String imageUrl;
        try {
            imageUrl = storage.uploadImage(imageFile, "exhibitors");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            result.reject("exhibitorLogo.image.invalid", ex.getMessage());
            return "admin/exhibitor-logo-form";
        }
        repository.save(apply(form, new ExhibitorLogo(), imageUrl));
        return "redirect:/admin/exhibitor-logos?saved";
    }

    @PostMapping("/admin/exhibitor-logos/bulk")
    public String createBulk(@RequestParam("imageFiles") List<MultipartFile> imageFiles,
                             @RequestParam("companyNames") List<String> companyNames,
                             @RequestParam("stallAllocations") List<String> stallAllocations,
                             @RequestParam(value = "websiteUrls", required = false) List<String> websiteUrls,
                             @RequestParam(value = "displayOrder", defaultValue = "0") int displayOrder,
                             RedirectAttributes redirectAttributes) {
        List<MultipartFile> selected = imageFiles == null ? List.of()
                : imageFiles.stream().filter(file -> file != null && !file.isEmpty()).toList();
        int count = selected.size();
        if (count == 0 || count > 20 || companyNames == null || companyNames.size() != count
                || stallAllocations == null || stallAllocations.size() != count
                || (websiteUrls != null && websiteUrls.size() != count)) {
            redirectAttributes.addFlashAttribute("errorMessage", "Select 1 to 20 photos and complete the details for each exhibitor.");
            return "redirect:/admin/exhibitor-logos";
        }
        if (displayOrder < 0 || displayOrder > Integer.MAX_VALUE - count) {
            redirectAttributes.addFlashAttribute("errorMessage", "Starting display order is outside the supported range.");
            return "redirect:/admin/exhibitor-logos";
        }
        for (int i = 0; i < count; i++) {
            String company = companyNames.get(i) == null ? "" : companyNames.get(i).trim();
            String stall = stallAllocations.get(i) == null ? "" : stallAllocations.get(i).trim();
            String website = websiteUrls == null || websiteUrls.get(i) == null ? "" : websiteUrls.get(i).trim();
            if (company.isBlank() || company.length() > 180 || stall.isBlank() || stall.length() > 80
                    || (!website.isBlank() && (website.length() > 500 || !website.matches("(?i)^https?://[^\\s]+$")))) {
                redirectAttributes.addFlashAttribute("errorMessage", "Check each company name, stall allocation, and website URL.");
                return "redirect:/admin/exhibitor-logos";
            }
        }

        List<String> uploadedUrls = new ArrayList<>(count);
        try {
            List<ExhibitorLogo> logos = new ArrayList<>(count);
            for (int i = 0; i < count; i++) {
                MultipartFile file = selected.get(i);
                String imageUrl = storage.uploadImage(file, "exhibitors");
                uploadedUrls.add(imageUrl);
                ExhibitorLogo logo = new ExhibitorLogo();
                logo.setCompanyName(companyNames.get(i).trim());
                logo.setStallAllocation(stallAllocations.get(i).trim());
                String website = websiteUrls == null ? "" : websiteUrls.get(i).trim();
                logo.setWebsiteUrl(website.isBlank() ? null : website);
                logo.setImageUrl(imageUrl);
                logo.setDisplayOrder(displayOrder + i);
                logo.setActive(true);
                logos.add(logo);
            }
            repository.saveAll(logos);
            redirectAttributes.addFlashAttribute("successMessage", logos.size() + " exhibitor photos uploaded successfully.");
        } catch (RuntimeException ex) {
            for (String uploadedUrl : uploadedUrls) {
                try {
                    storage.deleteStoredMedia(uploadedUrl);
                } catch (RuntimeException ignored) {
                    // Preserve the original bulk upload error for the admin.
                }
            }
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage() == null
                    ? "Unable to save exhibitor photos. Please try again." : ex.getMessage());
        }
        return "redirect:/admin/exhibitor-logos";
    }

    @PostMapping("/admin/exhibitor-logos/{id}")
    public String update(@PathVariable Long id,
                         @Valid @ModelAttribute("exhibitorLogoForm") ExhibitorLogoForm form,
                         BindingResult result,
                         @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                         Model model) {
        ExhibitorLogo logo = get(id);
        if (!result.hasErrors()) {
            try {
                String imageUrl = imageFile == null || imageFile.isEmpty()
                        ? logo.getImageUrl() : storage.uploadImage(imageFile, "exhibitors");
                repository.save(apply(form, logo, imageUrl));
                return "redirect:/admin/exhibitor-logos?updated";
            } catch (IllegalArgumentException | IllegalStateException ex) {
                result.reject("exhibitorLogo.image.invalid", ex.getMessage());
            }
        }
        model.addAttribute("logoId", id);
        model.addAttribute("mode", "edit");
        model.addAttribute("currentImageUrl", logo.getImageUrl());
        return "admin/exhibitor-logo-form";
    }

    @PostMapping("/admin/exhibitor-logos/{id}/toggle")
    public String toggle(@PathVariable Long id) {
        ExhibitorLogo logo = get(id);
        logo.setActive(!logo.isActive());
        repository.save(logo);
        return "redirect:/admin/exhibitor-logos";
    }

    @PostMapping("/admin/exhibitor-logos/{id}/delete")
    public String delete(@PathVariable Long id) {
        if (!repository.existsById(id)) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        repository.deleteById(id);
        return "redirect:/admin/exhibitor-logos";
    }

    private ExhibitorLogo get(Long id) {
        return repository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    private static ExhibitorLogoForm form(ExhibitorLogo logo) {
        ExhibitorLogoForm form = new ExhibitorLogoForm();
        form.setCompanyName(logo.getCompanyName());
        form.setStallAllocation(logo.getStallAllocation());
        form.setWebsiteUrl(logo.getWebsiteUrl());
        form.setDisplayOrder(logo.getDisplayOrder());
        form.setActive(logo.isActive());
        return form;
    }

    private static ExhibitorLogo apply(ExhibitorLogoForm form, ExhibitorLogo logo, String imageUrl) {
        logo.setCompanyName(form.getCompanyName().trim());
        logo.setStallAllocation(form.getStallAllocation().trim());
        logo.setWebsiteUrl(form.getWebsiteUrl() == null || form.getWebsiteUrl().isBlank() ? null : form.getWebsiteUrl().trim());
        logo.setDisplayOrder(form.getDisplayOrder());
        logo.setActive(form.isActive());
        logo.setImageUrl(imageUrl);
        return logo;
    }
}
