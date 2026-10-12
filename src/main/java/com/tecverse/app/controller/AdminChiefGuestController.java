package com.tecverse.app.controller;

import static org.springframework.http.HttpStatus.NOT_FOUND;
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

import com.tecverse.app.dto.ChiefGuestForm;
import com.tecverse.app.entity.ChiefGuest;
import com.tecverse.app.repository.ChiefGuestRepository;
import com.tecverse.app.service.GalleryStorageService;

import jakarta.validation.Valid;

@Controller
public class AdminChiefGuestController {

    private final ChiefGuestRepository chiefGuestRepository;
    private final GalleryStorageService galleryStorageService;

    public AdminChiefGuestController(ChiefGuestRepository chiefGuestRepository,
                                     GalleryStorageService galleryStorageService) {
        this.chiefGuestRepository = chiefGuestRepository;
        this.galleryStorageService = galleryStorageService;
    }

    @GetMapping("/admin/chief-guests")
    public String chiefGuests(Model model) {
        model.addAttribute("chiefGuests", chiefGuestRepository.findAllByOrderByDisplayOrderAscIdAsc());
        return "admin/chief-guests";
    }

    @GetMapping("/admin/chief-guests/new")
    public String newChiefGuest(Model model) {
        model.addAttribute("chiefGuestForm", new ChiefGuestForm());
        model.addAttribute("mode", "new");
        return "admin/chief-guest-form";
    }

    @GetMapping("/admin/chief-guests/{id}/edit")
    public String editChiefGuest(@PathVariable Long id, Model model) {
        ChiefGuest guest = guest(id);
        model.addAttribute("chiefGuestForm", form(guest));
        model.addAttribute("chiefGuestId", id);
        model.addAttribute("mode", "edit");
        model.addAttribute("currentImageUrl", guest.getImageUrl());
        return "admin/chief-guest-form";
    }

    @PostMapping("/admin/chief-guests")
    public String saveChiefGuest(@Valid @ModelAttribute("chiefGuestForm") ChiefGuestForm form,
                                 BindingResult bindingResult,
                                 @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                                 RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            return "admin/chief-guest-form";
        }

        try {
            ChiefGuest guest = new ChiefGuest();
            apply(form, guest, galleryStorageService.uploadImage(imageFile, "chief-guests"));
            chiefGuestRepository.save(guest);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.reject("chiefGuest.image.invalid", ex.getMessage());
            return "admin/chief-guest-form";
        }

        redirectAttributes.addFlashAttribute("successMessage", "Chief guest saved successfully.");
        return "redirect:/admin/chief-guests";
    }

    @PostMapping("/admin/chief-guests/{id}")
    public String updateChiefGuest(@PathVariable Long id,
                                   @Valid @ModelAttribute("chiefGuestForm") ChiefGuestForm form,
                                   BindingResult bindingResult,
                                   @RequestParam(value = "imageFile", required = false) MultipartFile imageFile,
                                   RedirectAttributes redirectAttributes,
                                   Model model) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("chiefGuestId", id);
            model.addAttribute("mode", "edit");
            model.addAttribute("currentImageUrl", guest(id).getImageUrl());
            return "admin/chief-guest-form";
        }

        ChiefGuest guest = guest(id);
        try {
            String imageUrl = imageFile == null || imageFile.isEmpty()
                    ? guest.getImageUrl()
                    : galleryStorageService.uploadImage(imageFile, "chief-guests");
            if (imageUrl == null || imageUrl.isBlank()) {
                throw new IllegalArgumentException("Please choose a guest photo.");
            }
            apply(form, guest, imageUrl);
            chiefGuestRepository.save(guest);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            bindingResult.reject("chiefGuest.image.invalid", ex.getMessage());
            model.addAttribute("chiefGuestId", id);
            model.addAttribute("mode", "edit");
            model.addAttribute("currentImageUrl", guest.getImageUrl());
            return "admin/chief-guest-form";
        }

        redirectAttributes.addFlashAttribute("successMessage", "Chief guest updated successfully.");
        return "redirect:/admin/chief-guests";
    }

    @PostMapping("/admin/chief-guests/{id}/toggle")
    public String toggleChiefGuest(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        ChiefGuest guest = guest(id);
        guest.setActive(!guest.isActive());
        chiefGuestRepository.save(guest);
        redirectAttributes.addFlashAttribute("successMessage", "Chief guest status updated.");
        return "redirect:/admin/chief-guests";
    }

    @PostMapping("/admin/chief-guests/{id}/delete")
    public String deleteChiefGuest(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        if (chiefGuestRepository.existsById(id)) {
            chiefGuestRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "Chief guest deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("successMessage", "Chief guest was already removed.");
        }
        return "redirect:/admin/chief-guests";
    }

    private ChiefGuest guest(Long id) {
        return chiefGuestRepository.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND));
    }

    private static void apply(ChiefGuestForm form, ChiefGuest guest, String imageUrl) {
        guest.setName(form.getName().trim());
        guest.setDesignation(form.getDesignation().trim());
        guest.setOrganization(form.getOrganization().trim());
        guest.setImageUrl(imageUrl);
        guest.setAccentColor(form.getAccentColor().trim());
        guest.setDisplayOrder(form.getDisplayOrder());
        guest.setActive(form.isActive());
    }

    private static ChiefGuestForm form(ChiefGuest guest) {
        ChiefGuestForm form = new ChiefGuestForm();
        form.setName(guest.getName());
        form.setDesignation(guest.getDesignation());
        form.setOrganization(guest.getOrganization());
        form.setAccentColor(guest.getAccentColor());
        form.setDisplayOrder(guest.getDisplayOrder());
        form.setActive(guest.isActive());
        return form;
    }

}
