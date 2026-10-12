package com.tecverse.app.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tecverse.app.entity.ConferenceScheduleItem;

public interface ConferenceScheduleItemRepository extends JpaRepository<ConferenceScheduleItem, Long> {

    List<ConferenceScheduleItem> findByActiveTrueOrderByDayNumberAscDisplayOrderAscIdAsc();

    List<ConferenceScheduleItem> findAllByOrderByDayNumberAscDisplayOrderAscIdAsc();
}
