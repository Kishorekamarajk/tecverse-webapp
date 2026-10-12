import 'package:flutter/material.dart';

enum MessageSender { user, assistant }

enum AiActionType {
  openHome,
  openFloorPlan,
  openSchedule,
  openSessions,
  openPass,
  openAbout,
  openProfile,
  openLogin,
}

class AiActionLink {
  final String label;
  final IconData icon;
  final AiActionType actionType;
  final String? targetId; // e.g. 'hall-3', 'quantum-session', etc.

  const AiActionLink({
    required this.label,
    required this.icon,
    required this.actionType,
    this.targetId,
  });
}

class AiMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final List<AiActionLink> actions;
  final bool isVoiceGenerated;
  final bool isNavigationCommand;

  const AiMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.actions = const [],
    this.isVoiceGenerated = false,
    this.isNavigationCommand = false,
  });
}
