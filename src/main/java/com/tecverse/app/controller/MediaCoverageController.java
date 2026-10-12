package com.tecverse.app.controller;

import java.util.List;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.tecverse.app.entity.MediaCoverage;
import com.tecverse.app.response.ApiResponse;
import com.tecverse.app.service.MediaCoverageService;

/**
 * JSON endpoint exposing the latest official TECVERSE social media posts, sourced
 * from PostgreSQL and kept fresh by {@link com.tecverse.app.scheduler.MediaCoverageScheduler}.
 * The homepage itself renders this same data server-side via {@link PageController#home}.
 */
@RestController
@RequestMapping("/api/media-coverage")
public class MediaCoverageController {

    private final MediaCoverageService mediaCoverageService;

    public MediaCoverageController(MediaCoverageService mediaCoverageService) {
        this.mediaCoverageService = mediaCoverageService;
    }

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<List<MediaCoverage>>> latest() {
        List<MediaCoverage> latest = mediaCoverageService.getLatestMediaCoverage();
        return ResponseEntity.ok(ApiResponse.success("Latest media coverage retrieved.", latest));
    }
}
