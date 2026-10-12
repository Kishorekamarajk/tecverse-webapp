package com.tecverse.app.controller;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Locale;

import static org.springframework.http.HttpStatus.NOT_FOUND;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.tecverse.app.dto.ImportantDateForm;
import com.tecverse.app.entity.ImportantDate;
import com.tecverse.app.repository.ImportantDateRepository;

import jakarta.validation.Valid;

@Controller
public class AdminImportantDateController {

    private static final DateTimeFormatter DATE_LABEL_FORMAT =
            DateTimeFormatter.ofPattern("d MMMM yyyy", Locale.ENGLISH);

    private final ImportantDateRepository importantDateRepository;

    public AdminImportantDateController(ImportantDateRepository importantDateRepository) {
        this.importantDateRepository = importantDateRepository;
    }

    @GetMapping("/admin/important-dates")
    public String importantDates(Model model) {
        model.addAttribute(
                "importantDates",
                importantDateRepository.findAllByOrderByDisplayOrderAscIdAsc()
        );

        return "admin/important-dates";
    }

    @GetMapping("/admin/important-dates/new")
    public String newImportantDate(Model model) {
        model.addAttribute("importantDateForm", new ImportantDateForm());
        model.addAttribute("mode", "new");

        return "admin/important-date-form";
    }

    @GetMapping("/admin/important-dates/{id}/edit")
    public String editImportantDate(
            @PathVariable Long id,
            Model model) {

        ImportantDate item = importantDate(id);

        model.addAttribute("importantDateForm", form(item));
        model.addAttribute("importantDateId", id);
        model.addAttribute("mode", "edit");

        return "admin/important-date-form";
    }

    @PostMapping("/admin/important-dates")
    public String saveImportantDate(
            @Valid @ModelAttribute("importantDateForm") ImportantDateForm form,
            BindingResult bindingResult,
            RedirectAttributes redirectAttributes) {

        if (bindingResult.hasErrors()) {
            return "admin/important-date-form";
        }

        ImportantDate item = new ImportantDate();

        apply(form, item);

        importantDateRepository.save(item);

        redirectAttributes.addFlashAttribute(
                "successMessage",
                "Important date saved successfully."
        );

        return "redirect:/admin/important-dates";
    }

    @PostMapping("/admin/important-dates/{id}")
    public String updateImportantDate(
            @PathVariable Long id,
            @Valid @ModelAttribute("importantDateForm") ImportantDateForm form,
            BindingResult bindingResult,
            Model model,
            RedirectAttributes redirectAttributes) {

        if (bindingResult.hasErrors()) {
            model.addAttribute("importantDateId", id);
            model.addAttribute("mode", "edit");

            return "admin/important-date-form";
        }

        ImportantDate item = importantDate(id);

        apply(form, item);

        importantDateRepository.save(item);

        redirectAttributes.addFlashAttribute(
                "successMessage",
                "Important date updated successfully."
        );

        return "redirect:/admin/important-dates";
    }

    @PostMapping("/admin/important-dates/{id}/toggle")
    public String toggleImportantDate(
            @PathVariable Long id,
            RedirectAttributes redirectAttributes) {

        ImportantDate item = importantDate(id);

        item.setActive(!item.isActive());

        importantDateRepository.save(item);

        redirectAttributes.addFlashAttribute(
                "successMessage",
                "Important date status updated."
        );

        return "redirect:/admin/important-dates";
    }

    @PostMapping("/admin/important-dates/{id}/delete")
    public String deleteImportantDate(
            @PathVariable Long id,
            RedirectAttributes redirectAttributes) {

        if (importantDateRepository.existsById(id)) {

            importantDateRepository.deleteById(id);

            redirectAttributes.addFlashAttribute(
                    "successMessage",
                    "Important date deleted successfully."
            );

        } else {

            redirectAttributes.addFlashAttribute(
                    "successMessage",
                    "Important date was already removed."
            );
        }

        return "redirect:/admin/important-dates";
    }

    private ImportantDate importantDate(Long id) {

        return importantDateRepository
                .findById(id)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND));
    }

    /** Copies the selected calendar date into the legacy VARCHAR database column as ISO yyyy-MM-dd. */
    private static void apply(
            ImportantDateForm form,
            ImportantDate item) {

        item.setTitle(form.getTitle().trim());

        item.setEventDate(form.getEventDate().toString());

        item.setDateLabel(form.getEventDate().format(DATE_LABEL_FORMAT));

        item.setIconClass(form.getIconClass().trim());

        item.setAccentColor(form.getAccentColor().trim());

        item.setDisplayOrder(form.getDisplayOrder());

        item.setActive(form.isActive());
    }

    /**
     * Converts entity into form object for editing.
     */
    private static ImportantDateForm form(ImportantDate item) {

        ImportantDateForm form = new ImportantDateForm();

        form.setTitle(item.getTitle());

        form.setEventDate(parseDate(item.getEventDate()));

        form.setIconClass(item.getIconClass());

        form.setAccentColor(item.getAccentColor());

        form.setDisplayOrder(item.getDisplayOrder());

        form.setActive(item.isActive());

        return form;
    }

    private static LocalDate parseDate(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return LocalDate.parse(value.trim());
        } catch (DateTimeParseException ignored) {
            // Legacy free-text dates must be reselected with the date picker before editing.
            return null;
        }
    }
}
