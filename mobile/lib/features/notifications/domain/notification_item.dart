import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String category; // ANNOUNCEMENT, ALERT, REMINDER, SCHEDULE, UPDATE
  final String priority; // HIGH, NORMAL, LOW
  final String? actionRoute;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.category = 'ANNOUNCEMENT',
    this.priority = 'NORMAL',
    this.actionRoute,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      if (json['createdAt'] != null) {
        parsedDate = DateTime.parse(json['createdAt'].toString());
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      category: (json['category']?.toString() ?? 'ANNOUNCEMENT').toUpperCase(),
      priority: (json['priority']?.toString() ?? 'NORMAL').toUpperCase(),
      actionRoute: json['actionRoute']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: parsedDate,
    );
  }

  NotificationItem copyWith({
    int? id,
    String? title,
    String? message,
    String? category,
    String? priority,
    String? actionRoute,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      actionRoute: actionRoute ?? this.actionRoute,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeAgoFormatted {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  IconData get icon {
    switch (category) {
      case 'ALERT':
        return Icons.warning_amber_rounded;
      case 'SCHEDULE':
        return Icons.calendar_month_rounded;
      case 'UPDATE':
        return Icons.location_on_outlined;
      case 'REMINDER':
        return Icons.access_time_rounded;
      case 'ANNOUNCEMENT':
      default:
        return Icons.campaign_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'ALERT':
        return AppColors.amberWarning;
      case 'SCHEDULE':
        return AppColors.indigoAccent;
      case 'UPDATE':
        return AppColors.secondaryGreen;
      case 'REMINDER':
        return AppColors.primaryOrangeLight;
      case 'ANNOUNCEMENT':
      default:
        return AppColors.primaryOrange;
    }
  }
}
