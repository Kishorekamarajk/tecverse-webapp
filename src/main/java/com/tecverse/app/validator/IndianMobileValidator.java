package com.tecverse.app.validator;

import com.tecverse.app.util.Constants;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class IndianMobileValidator implements ConstraintValidator<IndianMobile, String> {

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        return value != null && !value.isBlank() && value.trim().matches(Constants.INDIAN_MOBILE_REGEX);
    }
}
