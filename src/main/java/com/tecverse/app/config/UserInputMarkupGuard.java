package com.tecverse.app.config;

import java.beans.PropertyEditorSupport;

import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.InitBinder;

import com.tecverse.app.util.ValidationUtil;

/** Rejects markup in submitted form fields before controller logic receives them. */
@ControllerAdvice
public class UserInputMarkupGuard {

    @InitBinder
    public void rejectMarkupInFormFields(WebDataBinder binder) {
        binder.registerCustomEditor(String.class, new PropertyEditorSupport() {
            @Override
            public void setAsText(String text) {
                if (ValidationUtil.containsUnsafeMarkup(text)) {
                    throw new IllegalArgumentException("HTML tags and script input are not allowed.");
                }
                setValue(text);
            }
        });
    }
}
