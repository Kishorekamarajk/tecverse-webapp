package com.tecverse.app.validator;

import com.tecverse.app.util.Constants;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class GstinValidator implements ConstraintValidator<Gstin, String> {

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null || value.isBlank()) {
            return true;
        }
        return value.trim().toUpperCase().matches(Constants.GSTIN_REGEX);
    }
}
