package com.tecverse.app.validator;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Validates a required Indian mobile number: 10 digits starting with 6-9,
 * with an optional {@code +91} prefix.
 */
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = IndianMobileValidator.class)
public @interface IndianMobile {

    String message() default "{validation.indianMobile}";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
