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
        form.setDisplayOrder(logo.getDisplayOrder());
        form.setActive(logo.isActive());
        return form;
    }

    private static ExhibitorLogo apply(ExhibitorLogoForm form, ExhibitorLogo logo, String imageUrl) {
        logo.setCompanyName(form.getCompanyName().trim());
        logo.setStallAllocation(form.getStallAllocation().trim());
        logo.setDisplayOrder(form.getDisplayOrder());
        logo.setActive(form.isActive());
        logo.setImageUrl(imageUrl);
        return logo;
    }
}
