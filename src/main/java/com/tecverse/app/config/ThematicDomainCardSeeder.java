package com.tecverse.app.config;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.tecverse.app.entity.ThematicDomainCard;
import com.tecverse.app.repository.ThematicDomainCardRepository;

@Component
public class ThematicDomainCardSeeder implements ApplicationRunner {

    private final ThematicDomainCardRepository repository;

    public ThematicDomainCardSeeder(ThematicDomainCardRepository repository) {
        this.repository = repository;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (repository.count() == 0) {
            repository.saveAll(defaultCards());
        }
    }

    public static void restoreOriginalCards(ThematicDomainCardRepository repository) {
        repository.deleteAll();
        repository.saveAll(defaultCards());
    }

    private static List<ThematicDomainCard> defaultCards() {
        List<ThematicDomainCard> cards = new ArrayList<>();

        add(cards, "cdac", "Quantum Computing", "stars", "Exploring quantum technologies, algorithms and next-generation computing capabilities.", 10);
        add(cards, "cdac", "High Performance Computing", "cpu-fill", "Advanced computing infrastructure, parallel processing and scientific workloads.", 20);
        add(cards, "cdac", "Artificial Intelligence", "robot", "AI, machine learning and intelligent solutions for real-world public and industrial applications.", 30);
        add(cards, "cdac", "RISC-V & Digital Systems", "cpu", "Open processor architectures, embedded systems and indigenous digital technology.", 40);
        add(cards, "cdac", "Cyber Security", "shield-lock", "Cybersecurity technologies, secure systems and resilient digital infrastructure.", 50);
        add(cards, "cdac", "Software Solutions", "code-slash", "Enterprise software, digital platforms and technology-enabled transformation.", 60);
        add(cards, "cdac", "Strategic Sector", "flag", "Mission-critical technology for strategic, national and high-impact applications.", 70);
        add(cards, "cdac", "Blockchain", "link-45deg", "Distributed-ledger technologies and trusted digital transaction systems.", 80);

        add(cards, "sameer", "Nxt Gen Communication Technology", "reception-4", "Advanced wireless, RF and communication technologies for connected systems.", 10);
        add(cards, "sameer", "EMI / EMC / EMP & Safety", "shield-check", "Testing, measurement and consulting for electromagnetic compatibility and safety.", 20);
        add(cards, "sameer", "Atmospheric Instrumentation", "cloud-sun", "Sensing and instrumentation technologies for atmospheric and environmental applications.", 30);
        add(cards, "sameer", "Medical Devices", "heart-pulse-fill", "Electronics and instrumentation for healthcare, diagnostics and medical applications.", 40);
        add(cards, "sameer", "Smart IoT", "broadcast", "Connected sensing, embedded electronics and intelligent IoT systems.", 50);
        add(cards, "sameer", "Industrial Applications", "gear-wide-connected", "Applied electronics, RF and instrumentation solutions for industrial environments.", 60);

        add(cards, "cmet", "Semiconductor Materials & Devices", "memory", "Advanced materials, semiconductor processes and device technologies.", 10);
        add(cards, "cmet", "Power Electronics", "lightning-charge", "Power semiconductor technologies and efficient electronic power systems.", 20);
        add(cards, "cmet", "Additive Manufacturing & Packaging", "box-seam", "Advanced manufacturing and electronics packaging technologies.", 30);
        add(cards, "cmet", "Energy Generation & Storage", "battery-charging", "Materials and technologies for energy conversion, generation and storage.", 40);
        add(cards, "cmet", "E-waste & RoHS", "recycle", "Sustainable electronics, e-waste management and restricted-substance compliance.", 50);
        add(cards, "cmet", "Electronics Materials", "layers", "Functional materials and advanced materials research for electronics applications.", 60);

        return cards;
    }

    private static void add(List<ThematicDomainCard> cards, String institution, String title, String icon,
                            String description, int displayOrder) {
        ThematicDomainCard card = new ThematicDomainCard();
        card.setInstitution(institution);
        card.setTitle(title);
        card.setIcon(icon);
        card.setDescription(description);
        card.setDisplayOrder(displayOrder);
        card.setActive(true);
        cards.add(card);
    }
}
