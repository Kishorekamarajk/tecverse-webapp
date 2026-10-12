package com.tecverse.app.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.DashboardStatistic;

public interface DashboardStatisticRepository extends JpaRepository<DashboardStatistic, Long> {

    Optional<DashboardStatistic> findTopByOrderByUpdatedAtDescIdDesc();
}
