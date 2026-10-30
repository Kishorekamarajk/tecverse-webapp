package com.tecverse.app.service;

import java.util.List;
import java.util.Map;

import com.tecverse.app.entity.FaqItem;

public interface FaqService {

    String HOME = "home";
    String TICKET = "ticket";
    String RETREAT = "retreat";
    String PARTICIPANT = "participant";

    Map<String, String> labels();

    String cleanPageKey(String pageKey);

    String label(String pageKey);

    List<FaqItem> activeFaqs(String pageKey);
}
