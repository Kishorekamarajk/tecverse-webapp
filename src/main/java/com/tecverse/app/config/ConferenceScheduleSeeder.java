package com.tecverse.app.config;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.tecverse.app.entity.ConferenceScheduleItem;
import com.tecverse.app.repository.ConferenceScheduleItemRepository;

@Component
public class ConferenceScheduleSeeder implements ApplicationRunner {

    private final ConferenceScheduleItemRepository conferenceScheduleItemRepository;

    public ConferenceScheduleSeeder(ConferenceScheduleItemRepository conferenceScheduleItemRepository) {
        this.conferenceScheduleItemRepository = conferenceScheduleItemRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (conferenceScheduleItemRepository.count() > 0) {
            return;
        }

        conferenceScheduleItemRepository.saveAll(defaultSchedule());
    }

    private static List<ConferenceScheduleItem> defaultSchedule() {
        List<ConferenceScheduleItem> items = new ArrayList<>();
        LocalDate dayOne = LocalDate.of(2026, 11, 26);
        LocalDate dayTwo = LocalDate.of(2026, 11, 27);

        add(items, 1, dayOne, "Registration", "09:00 AM - 10:00 AM", "09:00", 10, true);
        add(items, 1, dayOne, "Arrival of Guests", "10:00 AM - 10:30 AM", "10:00", 20, false);
        add(items, 1, dayOne, "Inaugural Ceremony (Lamp Lighting)", "10:35 am - 10:45 am", "10:35", 30, false);
        add(items, 1, dayOne, "Tamil Thai Vazhthu", "10:45 am - 10:50 am", "10:45", 40, false);
        add(items, 1, dayOne, "C-DAC, Sameer & C-MET Achievements Video", "10:50 am - 11:00 am", "10:50", 50, false);
        add(items, 1, dayOne, "Keynote Address by Chief Guest", "11:00 am - 12:00 pm", "11:00", 60, false);
        add(items, 1, dayOne, "Product Launch / IoA / MoU", "12:00 pm - 12:45 pm", "12:00", 70, false);
        add(items, 1, dayOne, "Stall Visit by Chief Guest", "1:00 pm - 2:00 pm", "13:00", 80, false);
        add(items, 1, dayOne, "Lunch Break", "2:00 pm - 3:00 pm", "14:00", 90, false);
        add(items, 1, dayOne, "High Tea", "4:30 pm - 5:00 pm", "16:30", 100, false);
        add(items, 1, dayOne, "Cultural Program", "6:00 pm - 8:00 pm", "18:00", 110, false);
        add(items, 1, dayOne, "Dinner", "8:00 pm - 9:30 pm", "20:00", 120, false);

        add(items, 2, dayTwo, "Registration", "9:00 am - 10:00 am", "09:00", 10, false);
        add(items, 2, dayTwo, "Welcome Address", "10:00 am - 10:15 am", "10:00", 20, true);
        add(items, 2, dayTwo, "High Tea", "11:30 am - 11:45 am", "11:30", 30, false);
        add(items, 2, dayTwo, "Lunch Break", "2:00 pm - 3:00 pm", "14:00", 40, false);
        add(items, 2, dayTwo, "MoU Signing Inauguration", "3:00 pm - 3:10 pm", "15:00", 50, false);
        add(items, 2, dayTwo, "Keynote Address by Chief Guest", "3:20 pm - 3:40 pm", "15:20", 60, false);
        add(items, 2, dayTwo, "High Tea", "4:00 pm - 4:30 pm", "16:00", 70, false);
        add(items, 2, dayTwo, "Stall Visit by College Students", "3:00 pm - 6:30 pm", "15:00", 80, false);

        return items;
    }

    private static void add(List<ConferenceScheduleItem> items, int dayNumber, LocalDate date, String title,
                            String timeLabel, String timeValue, int displayOrder, boolean highlighted) {
        ConferenceScheduleItem item = new ConferenceScheduleItem();
        item.setDayNumber(dayNumber);
        item.setScheduleDate(date);
        item.setSessionTitle(title);
        item.setTimeLabel(timeLabel);
        item.setTimeValue(timeValue);
        item.setDisplayOrder(displayOrder);
        item.setHighlighted(highlighted);
        item.setActive(true);
        items.add(item);
    }
}
