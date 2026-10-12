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
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.tecverse.app.dto.FaqItemForm;
import com.tecverse.app.entity.FaqItem;
import com.tecverse.app.repository.FaqItemRepository;
import com.tecverse.app.service.FaqService;

import jakarta.validation.Valid;

@Controller
public class AdminFaqController {

    private final FaqItemRepository faqItemRepository;
    private final FaqService faqService;

    public AdminFaqController(FaqItemRepository faqItemRepository, FaqService faqService) {
        this.faqItemRepository = faqItemRepository;
        this.faqService = faqService;
    }

    @GetMapping("/admin/faqs")
    public String faqs(@RequestParam(value = "section", defaultValue = FaqService.HOME) String section, Model model) {
        String pageKey = faqService.cleanPageKey(section);
        model.addAttribute("activeSection", pageKey);
        model.addAttribute("sectionLabel", faqService.label(pageKey));
        model.addAttribute("faqSections", faqService.labels());
        model.addAttribute("faqs", faqItemRepository.findByPageKeyOrderByDisplayOrderAscIdAsc(pageKey));
        return "admin/faqs";
    }

    @GetMapping("/admin/faqs/new")
    public String newFaq(@RequestParam(value = "section", defaultValue = FaqService.HOME) String section, Model model) {
        FaqItemForm form = new FaqItemForm();
        form.setPageKey(faqService.cleanPageKey(section));
        model.addAttribute("faqItemForm", form);
        model.addAttribute("faqSections", faqService.labels());
        model.addAttribute("mode", "new");
        return "admin/faq-form";
    }

    @GetMapping("/admin/faqs/{id}/edit")
    public String editFaq(@PathVariable Long id, Model model) {
        FaqItem faq = faq(id);
        model.addAttribute("faqItemForm", form(faq));
        model.addAttribute("faqSections", faqService.labels());
        model.addAttribute("faqId", id);
        model.addAttribute("mode", "edit");
        return "admin/faq-form";
    }

    @PostMapping("/admin/faqs")
    public String saveFaq(@Valid @ModelAttribute("faqItemForm") FaqItemForm form,
                          BindingResult bindingResult,
                          Model model,
                          RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("faqSections", faqService.labels());
            return "admin/faq-form";
        }

        FaqItem faq = new FaqItem();
        apply(form, faq);
        faqItemRepository.save(faq);
        redirectAttributes.addFlashAttribute("successMessage", "FAQ saved successfully.");
        return "redirect:/admin/faqs?section=" + faq.getPageKey();
    }

    @PostMapping("/admin/faqs/{id}")
    public String updateFaq(@PathVariable Long id,
                            @Valid @ModelAttribute("faqItemForm") FaqItemForm form,
                            BindingResult bindingResult,
                            Model model,
                            RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            model.addAttribute("faqSections", faqService.labels());
            model.addAttribute("faqId", id);
            model.addAttribute("mode", "edit");
            return "admin/faq-form";
        }

        FaqItem faq = faq(id);
        apply(form, faq);
        faqItemRepository.save(faq);
        redirectAttributes.addFlashAttribute("successMessage", "FAQ updated successfully.");
        return "redirect:/admin/faqs?section=" + faq.getPageKey();
    }

    @PostMapping("/admin/faqs/{id}/toggle")
    public String toggleFaq(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        FaqItem faq = faq(id);
        faq.setActive(!faq.isActive());
        faqItemRepository.save(faq);
        redirectAttributes.addFlashAttribute("successMessage", "FAQ status updated.");
        return "redirect:/admin/faqs?section=" + faq.getPageKey();
    }

    @PostMapping("/admin/faqs/{id}/delete")
    public String deleteFaq(@PathVariable Long id,
                            @RequestParam(value = "section", defaultValue = FaqService.HOME) String section,
                            RedirectAttributes redirectAttributes) {
        String pageKey = faqService.cleanPageKey(section);
        FaqItem faq = faqItemRepository.findById(id).orElse(null);
        if (faq != null) {
            pageKey = faq.getPageKey();
            faqItemRepository.delete(faq);
            redirectAttributes.addFlashAttribute("successMessage", "FAQ deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("successMessage", "FAQ was already removed.");
        }
        return "redirect:/admin/faqs?section=" + pageKey;
    }

    private FaqItem faq(Long id) {
        return faqItemRepository.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND));
    }

    private void apply(FaqItemForm form, FaqItem faq) {
        faq.setPageKey(faqService.cleanPageKey(form.getPageKey()));
        faq.setQuestion(form.getQuestion().trim());
        faq.setAnswer(form.getAnswer().trim());
        faq.setDisplayOrder(form.getDisplayOrder());
        faq.setActive(form.isActive());
    }

    private static FaqItemForm form(FaqItem faq) {
        FaqItemForm form = new FaqItemForm();
        form.setPageKey(faq.getPageKey());
        form.setQuestion(faq.getQuestion());
        form.setAnswer(faq.getAnswer());
        form.setDisplayOrder(faq.getDisplayOrder());
        form.setActive(faq.isActive());
        return form;
    }
}
