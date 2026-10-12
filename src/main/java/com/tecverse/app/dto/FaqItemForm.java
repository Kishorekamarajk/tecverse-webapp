package com.tecverse.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public class FaqItemForm {

    @NotBlank(message = "Please choose a FAQ section.")
    @Size(max = 40, message = "FAQ section key must be 40 characters or less.")
    private String pageKey = "home";

    @NotBlank(message = "Question is required.")
    @Size(max = 300, message = "Question must be 300 characters or less.")
    private String question;

    @NotBlank(message = "Answer is required.")
    @Size(max = 10000, message = "Answer must be 10,000 characters or less.")
    private String answer;

    @PositiveOrZero(message = "Display order cannot be negative.")
    private int displayOrder = 0;

    private boolean active = true;

    public String getPageKey() {
        return pageKey;
    }

    public void setPageKey(String pageKey) {
        this.pageKey = pageKey;
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

    public String getAnswer() {
        return answer;
    }

    public void setAnswer(String answer) {
        this.answer = answer;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
