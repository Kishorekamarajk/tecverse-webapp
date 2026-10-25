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

import java.util.ArrayList;
import java.util.List;

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

    @PostMapping("/admin/chief-guests/bulk")
    public String saveChiefGuestsBulk(@RequestParam("imageFiles") List<MultipartFile> imageFiles,
                                      @RequestParam("names") List<String> names,
                                      @RequestParam("designations") List<String> designations,
                                      @RequestParam("organizations") List<String> organizations,
                                      @RequestParam("accentColors") List<String> accentColors,
                                      @RequestParam(value = "displayOrder", defaultValue = "0") int displayOrder,
                                      RedirectAttributes redirectAttributes) {
        List<MultipartFile> selected = imageFiles == null ? List.of()
                : imageFiles.stream().filter(file -> file != null && !file.isEmpty()).toList();
        int count = selected.size();
        if (count == 0 || count > 20 || names == null || names.size() != count
                || designations == null || designations.size() != count
                || organizations == null || organizations.size() != count
                || accentColors == null || accentColors.size() != count) {
            redirectAttributes.addFlashAttribute("errorMessage", "Select 1 to 20 photos and complete each chief guest's details.");
            return "redirect:/admin/chief-guests";
        }
        if (displayOrder < 0 || displayOrder > Integer.MAX_VALUE - count) {
            redirectAttributes.addFlashAttribute("errorMessage", "Starting display order is outside the supported range.");
            return "redirect:/admin/chief-guests";
        }
        for (int i = 0; i < count; i++) {
            String name = names.get(i) == null ? "" : names.get(i).trim();
            String designation = designations.get(i) == null ? "" : designations.get(i).trim();
            String organization = organizations.get(i) == null ? "" : organizations.get(i).trim();
            String accentColor = accentColors.get(i) == null ? "" : accentColors.get(i).trim();
            if (name.isBlank() || name.length() > 150 || designation.isBlank() || designation.length() > 180
                    || organization.isBlank() || organization.length() > 180
                    || !accentColor.matches("#[0-9A-Fa-f]{6}")) {
                redirectAttributes.addFlashAttribute("errorMessage", "Check each name, designation, organization, and accent color.");
                return "redirect:/admin/chief-guests";
            }
        }

        List<String> imageUrls = new ArrayList<>();
        try {
            imageUrls.addAll(galleryStorageService.uploadImages(selected, "chief-guests"));
            List<ChiefGuest> guests = new ArrayList<>(count);
            for (int i = 0; i < count; i++) {
                ChiefGuest guest = new ChiefGuest();
                guest.setName(names.get(i).trim());
                guest.setDesignation(designations.get(i).trim());
                guest.setOrganization(organizations.get(i).trim());
                guest.setAccentColor(accentColors.get(i).trim());
                guest.setImageUrl(imageUrls.get(i));
                guest.setDisplayOrder(displayOrder + i);
                guest.setActive(true);
                guests.add(guest);
            }
            chiefGuestRepository.saveAll(guests);
            redirectAttributes.addFlashAttribute("successMessage", guests.size() + " chief guests uploaded successfully.");
        } catch (RuntimeException ex) {
            for (String imageUrl : imageUrls) {
                try {
                    galleryStorageService.deleteStoredMedia(imageUrl);
                } catch (RuntimeException ignored) {
                    // Keep the original bulk upload error visible to the admin.
                }
            }
            redirectAttributes.addFlashAttribute("errorMessage", ex.getMessage() == null
                    ? "Unable to save chief guest photos. Please try again." : ex.getMessage());
        }
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
