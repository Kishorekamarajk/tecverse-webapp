import 'package:flutter/material.dart';
import '../../../core/navigation/voice_navigation_service.dart';
import '../domain/ai_message.dart';
import '../domain/faq_item.dart';
import 'faq_repository.dart';

/// Dynamic AI Copilot Engine for TEC-VERSE 2026.
///
/// Features:
/// - Natural Language Navigation Intent Processing ("Go to...", "Open...", "Where is...")
/// - Dynamic database synchronization with PostgreSQL `faq_items` table
/// - Voice Speech-to-Intent translation
class TecverseAiService {
  TecverseAiService._();

  static final FaqRepository _faqRepo = FaqRepository();
  static List<FaqItem> _cachedDbFaqs = [];
  static bool _isLoading = false;

  /// Default baseline matching all 22 rows in PostgreSQL `faq_items` table
  static final List<FaqItem> _initialFaqs = [
    const FaqItem(
      id: 1,
      pageKey: 'home',
      question: 'What is Tec-verse 2026?',
      answer: '🌟 **Tec-verse 2026** is India\'s premier Technology & Engineering Exhibition and Conference organized by the Consortium of Scientific Societies (CSC) under MeitY, Government of India, along with C-DAC, SAMEER, and C-MET.\n\n📍 **Venue:** Chennai Trade Centre, Nandambakkam, Chennai\n🗓️ **Dates:** 26–27 November 2026\n🎯 **Focus Areas:** Quantum Computing, Semiconductor VLSI, Generative AI, Robotics, 6G & Advanced Materials.',
      displayOrder: 1,
    ),
    const FaqItem(
      id: 2,
      pageKey: 'home',
      question: 'Is Tec-verse 2026 only for IT companies?',
      answer: '🌐 **No, Tec-verse 2026 is open to all domains!**\n\nIt brings together Electronics, Semiconductors, Hardware Design, Defense Technology, Deep Tech Startups, Academic Researchers, and Government Scientific Institutions alongside IT & Software enterprises.',
      displayOrder: 2,
    ),
    const FaqItem(
      id: 3,
      pageKey: 'home',
      question: 'Will there be networking opportunities?',
      answer: '🤝 **Yes, extensive B2B & Research Networking!**\n\n• **B2B Matchmaking Lounges** in Hall 2 & 3\n• **Executive Dinners & MoU Signing Pavilions**\n• **Direct interaction with MeitY, C-DAC, SAMEER, & C-MET leadership**\n• **Startup Investor Pitching Arenas**',
      displayOrder: 3,
    ),
    const FaqItem(
      id: 4,
      pageKey: 'home',
      question: 'Why should I exhibit at Tec-verse 2026?',
      answer: '🏢 **Exhibitor Benefits:**\n\n• Showcase innovations to **10,000+ delegates and international buyers**\n• High-visibility standard (3x3m) and premium (6x6m) stalls at Chennai Trade Centre\n• Direct government procurement & industry partnership opportunities\n• Brand coverage across national media and conference proceedings.',
      displayOrder: 4,
    ),
    const FaqItem(
      id: 5,
      pageKey: 'retreat',
      question: 'Who can attend the leadership retreat?',
      answer: '🏕️ **Leadership Retreat Eligibility:**\n\nSenior scientists, academic chairs, industry executives, startup founders, and invited delegates can participate in the exclusive technical retreat and round-table discussions.',
      displayOrder: 5,
    ),
    const FaqItem(
      id: 6,
      pageKey: 'retreat',
      question: 'How are speakers selected?',
      answer: '🎤 **Speaker Selection Process:**\n\nSpeakers are chosen by the **National Technical Program Committee (TPC)** comprising eminent scientists from MeitY, C-DAC, IITs, and industry fellows based on research merit and breakthrough innovations.',
      displayOrder: 6,
    ),
    const FaqItem(
      id: 7,
      pageKey: 'retreat',
      question: 'Can industry organizations participate?',
      answer: '🏭 **Yes, Industry Participation is Welcomed!**\n\nIndustry organizations can participate as **Sponsors, Exhibitors, Panelists, and Technology Partners** to demonstrate cutting-edge products and hire top engineering talent.',
      displayOrder: 7,
    ),
    const FaqItem(
      id: 8,
      pageKey: 'retreat',
      question: 'How can researchers present projects?',
      answer: '🔬 **Research Project Presentations:**\n\nResearchers can submit extended abstracts and technical papers through the official portal. Selected papers are published in conference proceedings and presented in the Plenary Track.',
      displayOrder: 8,
    ),
    const FaqItem(
      id: 9,
      pageKey: 'ticket',
      question: 'Is there any registration fee for the event?',
      answer: '🎟️ **Registration & Fee Details:**\n\n• **Standard Delegate:** Complimentary passes available for registered academic and scientific delegates through government sponsorship.\n• **Corporate / Industry Pass:** Available with full access to exhibition halls, executive dining, and conference kits.',
      displayOrder: 9,
    ),
    const FaqItem(
      id: 10,
      pageKey: 'ticket',
      question: 'Will food be provided at the event?',
      answer: '🍱 **Dining & Hospitality:**\n\n**Yes!** Complimentary high-tea, snacks, and an executive buffet lunch are provided for all registered delegates at the **Lawn Pavilion behind Hall 3** on both Day 1 (26 Nov) and Day 2 (27 Nov).',
      displayOrder: 10,
    ),
    const FaqItem(
      id: 11,
      pageKey: 'ticket',
      question: 'How can I register for the event?',
      answer: '📝 **How to Register:**\n\n1. Register online at `tecverse2026.cdac.in` or via the in-app registration screen.\n2. Complete your profile and select your technology interest domains.\n3. Instantly receive your **Encrypted QR Digital Pass** in the app for fast-track entry.',
      displayOrder: 11,
    ),
    const FaqItem(
      id: 12,
      pageKey: 'ticket',
      question: 'Will I receive a confirmation after registration?',
      answer: '📧 **Registration Confirmation:**\n\n**Yes!** Immediately upon registration, you will receive an official confirmation email with your **Registration Reference Number** and your **Digital Pass QR badge** will activate in this app.',
      displayOrder: 12,
    ),
    const FaqItem(
      id: 13,
      pageKey: 'floor_plan',
      question: 'Where is Chennai Trade Centre located?',
      answer: '📍 **Venue Location:**\n\n**Chennai Trade Centre (CTC)**\nMount-Poonamallee High Road, Nandambakkam, Chennai, Tamil Nadu 600089.\nConveniently located 10 minutes from Chennai International Airport and Guindy Metro Station.',
      displayOrder: 13,
    ),
    const FaqItem(
      id: 14,
      pageKey: 'floor_plan',
      question: 'Which hall has the Quantum Computing and AI exhibits?',
      answer: '🤖 **Quantum & AI Exhibits:**\n\n• **Hall 1 & 2:** Quantum Computing, PARAM Supercomputing (C-DAC) & High Performance Computing (HPC)\n• **Hall 3 & 4:** Generative AI, Robotics & Autonomous Systems\n• **Hall 5 & 6:** Semiconductor VLSI & Advanced Sensors\n• **Hall 7 & 8:** 6G Wireless Communications & Defence Electronics.',
      displayOrder: 14,
    ),
    const FaqItem(
      id: 15,
      pageKey: 'floor_plan',
      question: 'Where is the Help Desk and Registration Counter?',
      answer: 'ℹ️ **Help Desk & Badge Printing:**\n\nThe Central Registration Desk, Fast-Track QR Scanner, and Information Booth are located at the **Grand Convention Foyer (Entry Gate 1 & 2)**.',
      displayOrder: 15,
    ),
    const FaqItem(
      id: 16,
      pageKey: 'schedule',
      question: 'What are the daily exhibition timings?',
      answer: '⏰ **Exhibition & Conference Timings:**\n\n• **Day 1 (26 Nov 2026):** 09:00 AM – 06:30 PM (Inauguration at 10:00 AM)\n• **Day 2 (27 Nov 2026):** 09:30 AM – 06:00 PM (Valedictory & Awards at 04:30 PM)',
      displayOrder: 16,
    ),
    const FaqItem(
      id: 17,
      pageKey: 'schedule',
      question: 'When is the Keynote Address on Quantum Computing?',
      answer: '⚡ **Quantum Keynote:**\n\n**Day 1 (26 Nov 2026) at 11:30 AM** in **Main Auditorium (Hall 1)**.\nDelivered by chief scientists from MeitY and C-DAC on National Quantum Mission milestones.',
      displayOrder: 17,
    ),
  ];

  /// Fetch questions & answers directly from PostgreSQL `faq_items` table
  static Future<List<FaqItem>> fetchFaqItemsFromDb({bool forceRefresh = false}) async {
    if (_cachedDbFaqs.isNotEmpty && !forceRefresh) {
      return _cachedDbFaqs;
    }

    if (_isLoading) {
      return _cachedDbFaqs.isNotEmpty ? _cachedDbFaqs : _initialFaqs;
    }

    _isLoading = true;
    try {
      final items = await _faqRepo.fetchFaqItems();
      if (items.isNotEmpty) {
        _cachedDbFaqs = items;
      } else if (_cachedDbFaqs.isEmpty) {
        _cachedDbFaqs = _initialFaqs;
      }
    } catch (_) {
      if (_cachedDbFaqs.isEmpty) {
        _cachedDbFaqs = _initialFaqs;
      }
    } finally {
      _isLoading = false;
    }

    return _cachedDbFaqs;
  }

  /// Get all FAQ items
  static Future<List<FaqItem>> getAllFaqItems() async {
    return fetchFaqItemsFromDb();
  }

  /// Get quick suggestion prompt questions dynamically rendered from `faq_items` database
  static Future<List<String>> getSamplePrompts() async {
    final faqs = await fetchFaqItemsFromDb();
    final list = <String>[
      'Go to Sessions',
      'Go to Floor Plan',
      'Go to Digital Pass',
      'Go to Schedule',
    ];
    list.addAll(faqs.map((faq) => faq.question).take(6));
    return list;
  }

  /// Process delegate query dynamically by checking Voice Navigation and PostgreSQL DB
  static Future<AiMessage> processQuery(String query, {bool isVoice = false}) async {
    final trimmed = query.trim();

    // 1. Check Voice Navigation Intent ("Go to...", "Open...", "Show...", etc.)
    final navResult = VoiceNavigationService.evaluateNavigationIntent(trimmed);
    if (navResult.isNavigation && navResult.destination != null) {
      final List<AiActionLink> navActions = [];
      
      switch (navResult.destination!) {
        case VoiceNavDestination.home:
          navActions.add(const AiActionLink(
            label: 'Open Home',
            icon: Icons.home_rounded,
            actionType: AiActionType.openHome,
          ));
          break;
        case VoiceNavDestination.sessions:
          navActions.add(const AiActionLink(
            label: 'Open Sessions',
            icon: Icons.category_rounded,
            actionType: AiActionType.openSessions,
          ));
          break;
        case VoiceNavDestination.schedule:
          navActions.add(const AiActionLink(
            label: 'Open Schedule',
            icon: Icons.calendar_today_rounded,
            actionType: AiActionType.openSchedule,
          ));
          break;
        case VoiceNavDestination.digitalPass:
          navActions.add(const AiActionLink(
            label: 'Open Digital Pass',
            icon: Icons.qr_code_2_rounded,
            actionType: AiActionType.openPass,
          ));
          break;
        case VoiceNavDestination.about:
          navActions.add(const AiActionLink(
            label: 'Open About Conclave',
            icon: Icons.info_outline_rounded,
            actionType: AiActionType.openAbout,
          ));
          break;
        case VoiceNavDestination.profile:
          navActions.add(const AiActionLink(
            label: 'Open Profile',
            icon: Icons.person_rounded,
            actionType: AiActionType.openProfile,
          ));
          break;
        case VoiceNavDestination.floorPlan:
          navActions.add(const AiActionLink(
            label: 'View Floor Plan',
            icon: Icons.map_rounded,
            actionType: AiActionType.openFloorPlan,
          ));
          break;
        case VoiceNavDestination.login:
          navActions.add(const AiActionLink(
            label: 'Open Login',
            icon: Icons.lock_open_rounded,
            actionType: AiActionType.openLogin,
          ));
          break;
      }

      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: navResult.feedbackMessage,
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
        actions: navActions,
        isVoiceGenerated: isVoice,
        isNavigationCommand: true,
      );
    }

    final normalized = trimmed.toLowerCase().replaceAll('?', '').replaceAll('!', '').replaceAll('-', ' ');

    // 2. Direct search from PostgreSQL backend /api/faq/search if online
    try {
      final searchResults = await _faqRepo.searchFaq(normalized);
      if (searchResults.isNotEmpty) {
        return searchResults.first.toAiMessage(isVoice: isVoice);
      }
    } catch (_) {}

    // 3. Search against dynamically loaded faq_items rows from database
    final dbFaqs = await fetchFaqItemsFromDb();

    if (dbFaqs.isNotEmpty) {
      FaqItem? bestMatch;
      int highestScore = 0;

      for (final faq in dbFaqs) {
        int score = 0;

        final qNorm = faq.question.toLowerCase().replaceAll('?', '').replaceAll('-', ' ');
        final aNorm = faq.answer.toLowerCase().replaceAll('-', ' ');
        final pkNorm = faq.pageKey.toLowerCase();

        // Exact match or substring on question
        if (qNorm == normalized || qNorm.contains(normalized) || normalized.contains(qNorm)) {
          score += 25;
        }

        // Token overlap matching on question and answer
        final queryTokens = normalized.split(RegExp(r'\s+')).where((t) => t.length > 2);
        for (final token in queryTokens) {
          if (qNorm.contains(token)) {
            score += 6;
          } else if (pkNorm.contains(token)) {
            score += 4;
          } else if (aNorm.contains(token)) {
            score += 2;
          }
        }

        if (score > highestScore) {
          highestScore = score;
          bestMatch = faq;
        }
      }

      if (bestMatch != null && highestScore >= 3) {
        return bestMatch.toAiMessage(isVoice: isVoice);
      }
    }

    // Default message when no matching record is found in `faq_items` database
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '🤖 I couldn\'t find a precise match in the `faq_items` database.\n\n'
          'Try saying or typing:\n'
          '• **"Go to Sessions"** or **"Go to Floor Plan"**\n'
          '• **"Go to Digital Pass"** or **"Go to Schedule"**\n'
          '• **"What is Tec-verse 2026?"**\n'
          '• **"Where is Chennai Trade Centre?"**\n'
          '• **"Will food be provided?"**',
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      isVoiceGenerated: isVoice,
      actions: const [
        AiActionLink(
          label: 'View Floor Plan',
          icon: Icons.map_outlined,
          actionType: AiActionType.openFloorPlan,
        ),
        AiActionLink(
          label: 'Explore Sessions',
          icon: Icons.category_rounded,
          actionType: AiActionType.openSessions,
        ),
      ],
    );
  }
}
