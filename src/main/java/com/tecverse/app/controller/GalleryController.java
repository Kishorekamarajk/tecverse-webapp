package com.tecverse.app.controller;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.tecverse.app.dto.GalleryContentResponse;
import com.tecverse.app.response.ApiResponse;
import com.tecverse.app.service.GalleryService;

@RestController
@RequestMapping("/api/gallery")
public class GalleryController {

    private final GalleryService galleryService;

    public GalleryController(GalleryService galleryService) {
        this.galleryService = galleryService;
    }

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<GalleryContentResponse>> gallery() {
        return ResponseEntity.ok(ApiResponse.success("Gallery content retrieved.", galleryService.getActiveGalleryContent()));
    }
}
