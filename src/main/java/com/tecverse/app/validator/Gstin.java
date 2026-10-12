package com.tecverse.app.validator;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Validates an optional 15-character Indian GSTIN. Blank/null values are treated as valid -
 * pair with {@code @NotBlank} on the field if it becomes mandatory.
 */
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = GstinValidator.class)
public @interface Gstin {

    String message() default "{validation.gstin}";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
