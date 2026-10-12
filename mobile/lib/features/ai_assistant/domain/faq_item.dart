import 'package:flutter/material.dart';
import 'ai_message.dart';

/// Models a row from the PostgreSQL `faq_items` database table.
class FaqItem {
  final int? id;
  final String pageKey;
  final String question;
  final String answer;
  final int displayOrder;

  const FaqItem({
    this.id,
    this.pageKey = 'home',
    required this.question,
    required this.answer,
    this.displayOrder = 1,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] is int ? json['id'] : null,
      pageKey: json['pageKey']?.toString() ?? json['page_key']?.toString() ?? 'home',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      displayOrder: json['displayOrder'] is int
          ? json['displayOrder']
          : (json['display_order'] is int ? json['display_order'] : 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageKey': pageKey,
      'question': question,
      'answer': answer,
      'displayOrder': displayOrder,
    };
  }

  /// Converts this database FAQ row into an interactive AI chat message
  AiMessage toAiMessage({bool isVoice = false}) {
    final List<AiActionLink> actions = [];
    final lowerQ = question.toLowerCase();

    // Dynamically deduce deep-link action button based on content
    if (pageKey == 'ticket' || lowerQ.contains('register') || lowerQ.contains('fee') || lowerQ.contains('confirmation') || lowerQ.contains('pass')) {
      actions.add(
        const AiActionLink(
          label: 'Open Digital Pass',
          icon: Icons.qr_code_2_rounded,
          actionType: AiActionType.openPass,
        ),
      );
    } else if (lowerQ.contains('exhibit') || lowerQ.contains('hall') || lowerQ.contains('where') || lowerQ.contains('stall')) {
      actions.add(
        const AiActionLink(
          label: 'View Floor Plan',
          icon: Icons.map_outlined,
          actionType: AiActionType.openFloorPlan,
        ),
      );
    } else if (pageKey == 'retreat' || lowerQ.contains('session') || lowerQ.contains('speaker') || lowerQ.contains('researcher') || lowerQ.contains('schedule')) {
      actions.add(
        const AiActionLink(
          label: 'Explore Schedule',
          icon: Icons.calendar_today_rounded,
          actionType: AiActionType.openSchedule,
        ),
      );
    } else {
      actions.add(
        const AiActionLink(
          label: 'Explore Thematic Tracks',
          icon: Icons.category_rounded,
          actionType: AiActionType.openSessions,
        ),
      );
    }

    return AiMessage(
      id: id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: answer,
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      actions: actions,
      isVoiceGenerated: isVoice,
    );
  }
}
