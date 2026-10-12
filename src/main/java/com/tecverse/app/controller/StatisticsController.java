package com.tecverse.app.controller;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.tecverse.app.dto.StatisticsResponse;
import com.tecverse.app.service.StatisticsService;

@RestController
public class StatisticsController {

    private final StatisticsService statisticsService;

    public StatisticsController(StatisticsService statisticsService) {
        this.statisticsService = statisticsService;
    }

    @GetMapping(value = "/api/statistics", produces = MediaType.APPLICATION_JSON_VALUE)
    public StatisticsResponse getStatistics() {
        return statisticsService.getStatistics();
    }
}
