package com.tecverse.app.controller;

import java.util.List;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.tecverse.app.dto.ChatbotFaq;
import com.tecverse.app.response.ApiResponse;
import com.tecverse.app.service.ChatbotFaqService;

@RestController
@RequestMapping("/api/chatbot")
public class ChatbotController {

    private final ChatbotFaqService chatbotFaqService;

    public ChatbotController(ChatbotFaqService chatbotFaqService) {
        this.chatbotFaqService = chatbotFaqService;
    }

    @GetMapping(value = "/faqs", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<List<ChatbotFaq>>> faqs() {
        return ResponseEntity.ok(ApiResponse.success("Chatbot FAQ loaded.", chatbotFaqService.getFaqs()));
    }
}
