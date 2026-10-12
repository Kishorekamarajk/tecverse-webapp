package com.tecverse.app.service.impl;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.tecverse.app.entity.FaqItem;
import com.tecverse.app.repository.FaqItemRepository;
import com.tecverse.app.service.FaqService;

@Service
public class FaqServiceImpl implements FaqService {

    private static final Map<String, String> LABELS = new LinkedHashMap<>();

    static {
        LABELS.put(HOME, "Home FAQ");
        LABELS.put(TICKET, "Ticket FAQ");
        LABELS.put(RETREAT, "At a Glance FAQ");
    }

    private final FaqItemRepository faqItemRepository;

    public FaqServiceImpl(FaqItemRepository faqItemRepository) {
        this.faqItemRepository = faqItemRepository;
    }

    @Override
    public Map<String, String> labels() {
        return LABELS;
    }

    @Override
    public String cleanPageKey(String pageKey) {
        String key = pageKey == null ? "" : pageKey.trim().toLowerCase(Locale.ENGLISH);
        return LABELS.containsKey(key) ? key : HOME;
    }

    @Override
    public String label(String pageKey) {
        return LABELS.getOrDefault(cleanPageKey(pageKey), LABELS.get(HOME));
    }

    @Override
    public List<FaqItem> activeFaqs(String pageKey) {
        return faqItemRepository.findByPageKeyAndActiveTrueOrderByDisplayOrderAscIdAsc(cleanPageKey(pageKey));
    }
}
