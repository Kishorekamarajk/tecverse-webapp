package com.tecverse.app.service.impl;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.tecverse.app.dto.StatisticsResponse;
import com.tecverse.app.entity.DashboardStatistic;
import com.tecverse.app.repository.DashboardStatisticRepository;
import com.tecverse.app.service.StatisticsService;

@Service
public class StatisticsServiceImpl implements StatisticsService {

    private final DashboardStatisticRepository dashboardStatisticRepository;

    public StatisticsServiceImpl(DashboardStatisticRepository dashboardStatisticRepository) {
        this.dashboardStatisticRepository = dashboardStatisticRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public StatisticsResponse getStatistics() {
        DashboardStatistic statistic = dashboardStatisticRepository.findTopByOrderByUpdatedAtDescIdDesc()
                .orElse(null);

        if (statistic == null) {
            return new StatisticsResponse(0, 0, 0, 0, 0);
        }

        return new StatisticsResponse(
                statistic.getParticipants(),
                statistic.getSpeakers(),
                statistic.getOrganizations(),
                statistic.getSessions(),
                statistic.getPartners()
        );
    }
}
