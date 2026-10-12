package com.tecverse.app.validator;

import com.tecverse.app.dto.InquiryForm;
import com.tecverse.app.util.ContactPhoneNumbers;
import org.springframework.validation.Errors;
import org.springframework.validation.Validator;

/** Cross-field validation in addition to the DTO's Bean Validation constraints. */
public class InquiryFormValidator implements Validator {
    @Override
    public boolean supports(Class<?> type) {
        return InquiryForm.class.isAssignableFrom(type);
    }
    @Override
    public void validate(Object target, Errors errors) {
        InquiryForm form = (InquiryForm) target;
        if (form.getCountry() == null || form.getCountry().isBlank()) {
            errors.rejectValue("country", "contact.country.required", "Country code is required.");
            return;
        }
        if (!ContactPhoneNumbers.supported(form.getCountry())) {
            errors.rejectValue("country", "contact.country.invalid", "Select a valid country.");
            return;
        }
        if (!"IN".equalsIgnoreCase(form.getCountry())) {
            errors.rejectValue("phone", "contact.phone.indiaOnly", "Only Indian mobile numbers are accepted.");
            return;
        }
        if (form.getPhone() == null || form.getPhone().isBlank()) {
            errors.rejectValue("phone", "contact.phone.required", "Phone number is required.");
            return;
        }
        try {
            ContactPhoneNumbers.normalizeIndianMobile(form.getPhone());
        } catch (IllegalArgumentException ex) {
            errors.rejectValue("phone", "contact.phone.invalid", ex.getMessage());
        }
    }
}
