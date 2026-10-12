import '../../../core/constants/api_constants.dart';
import '../../../core/networking/api_client.dart';
import '../presentation/schedule_screen.dart';

/// Repository responsible for loading conference schedule items from local PostgreSQL database.
class ScheduleRepository {
  final ApiClient client;

  ScheduleRepository({ApiClient? client}) : client = client ?? ApiClient();

  /// Fetches schedule events grouped by day number (1 -> Day 1 events, 2 -> Day 2 events).
  Future<Map<int, List<ConferenceEvent>>> fetchScheduleEvents() async {
    try {
      final response = await client.get(ApiConstants.scheduleEndpoint);
      if (response is List) {
        final Map<int, List<ConferenceEvent>> grouped = {1: [], 2: []};

        for (final item in response) {
          if (item is Map<String, dynamic>) {
            final int dayNumber = item['dayNumber'] is int ? item['dayNumber'] : 1;
            final String title = item['sessionTitle']?.toString() ?? 'Session';
            final String timeLabel = item['timeLabel']?.toString() ?? '09:00 AM - 10:00 AM';
            final bool highlighted = item['highlighted'] == true;

            // Split timeLabel into startTime and endTime
            String startTime = '09:00 AM';
            String endTime = '10:00 AM';
            if (timeLabel.contains('-')) {
              final parts = timeLabel.split('-');
              startTime = parts[0].trim();
              endTime = parts[1].trim();
            } else {
              startTime = timeLabel.trim();
            }

            // Map category based on session title keywords
            final EventCategory category = _determineCategory(title);

            final event = ConferenceEvent(
              time: startTime,
              endTime: endTime,
              title: title,
              category: category,
              isHighlight: highlighted,
            );

            grouped.putIfAbsent(dayNumber, () => []).add(event);
          }
        }

        if (grouped[1]!.isNotEmpty || grouped[2]!.isNotEmpty) {
          return grouped;
        }
      }
    } catch (_) {
      // Allow caller / screen to handle fallback gracefully
    }
    return {};
  }

  static EventCategory _determineCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('registration')) return EventCategory.registration;
    if (lower.contains('ceremony') || lower.contains('lamp') || lower.contains('vazhthu')) return EventCategory.ceremony;
    if (lower.contains('keynote') || lower.contains('address') || lower.contains('talk')) return EventCategory.keynote;
    if (lower.contains('lunch')) return EventCategory.lunch;
    if (lower.contains('tea') || lower.contains('break')) return EventCategory.tea;
    if (lower.contains('stall') || lower.contains('exhibition')) return EventCategory.stall;
    if (lower.contains('mou')) return EventCategory.mou;
    if (lower.contains('welcome') || lower.contains('arrival')) return EventCategory.welcome;
    if (lower.contains('award') || lower.contains('felicitation') || lower.contains('cultural')) return EventCategory.cultural;
    if (lower.contains('network')) return EventCategory.networking;
    return EventCategory.general;
  }
}
