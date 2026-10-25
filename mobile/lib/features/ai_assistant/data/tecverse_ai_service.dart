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

  /// Fetch questions & answers directly from PostgreSQL `faq_items` table
  static Future<List<FaqItem>> fetchFaqItemsFromDb({bool forceRefresh = false}) async {
    if (_cachedDbFaqs.isNotEmpty && !forceRefresh) {
      return _cachedDbFaqs;
    }

    if (_isLoading) {
      return _cachedDbFaqs;
    }

    _isLoading = true;
    try {
      final items = await _faqRepo.fetchFaqItems();
      if (items.isNotEmpty) {
        _cachedDbFaqs = items;
      }
    } catch (_) {
      // Keep whatever was cached; an empty cache means the next query retries the server.
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

    if (dbFaqs.isEmpty) {
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'I can\'t reach the TEC-VERSE server right now, so I can\'t look up answers.\n\n'
            'Please check your internet connection and try again. You can still say '
            '**"Go to Schedule"** or **"Go to Digital Pass"** to open a screen.',
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
        isVoiceGenerated: isVoice,
      );
    }

    // Default message when no FAQ matches the question
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'I couldn\'t find an answer to that in the TEC-VERSE FAQs.\n\n'
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
