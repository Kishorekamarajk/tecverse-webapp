import '../../../core/constants/api_constants.dart';
import '../../../core/networking/api_client.dart';
import '../domain/important_date_item.dart';
import 'important_dates_data.dart';
import '../presentation/widgets/recommended_session_card.dart';

class EventSummary {
  final String title;
  final String headline;
  final String heroBadge;
  final String heroSubtitle;
  final String venue;
  final int visitorCount;
  final int exhibitorCount;
  final int speakerCount;
  final String description;

  const EventSummary({
    required this.title,
    required this.headline,
    required this.heroBadge,
    required this.heroSubtitle,
    required this.venue,
    required this.visitorCount,
    required this.exhibitorCount,
    required this.speakerCount,
    required this.description,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    return EventSummary(
      title: json['title']?.toString() ?? 'TEC-VERSE 2026',
      headline: json['headline']?.toString() ?? 'Beacon of Rising Tech Innovation & AI',
      heroBadge: json['heroBadge']?.toString() ?? '26-27-28 Nov 2026',
      heroSubtitle: json['heroSubtitle']?.toString() ?? 'Explore. Innovate. Empower the Future.',
      venue: json['venue']?.toString() ?? 'Chennai Trade Centre, Mount Poonamallee Road, Nandambakkam, Chennai – 600089',
      visitorCount: json['visitorCount'] is int ? json['visitorCount'] : 15000,
      exhibitorCount: json['exhibitorCount'] is int ? json['exhibitorCount'] : 250,
      speakerCount: json['speakerCount'] is int ? json['speakerCount'] : 25,
      description: json['description']?.toString() ?? 'India’s premier platform for technology, entrepreneurship, and breakthrough innovation.',
    );
  }
}

class TechnologyDomainItem {
  final int id;
  final String title;
  final String description;
  final String icon;
  final String institution;

  const TechnologyDomainItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.institution,
  });

  factory TechnologyDomainItem.fromJson(Map<String, dynamic> json) {
    return TechnologyDomainItem(
      id: json['id'] is int ? json['id'] : 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'cpu',
      institution: json['institution']?.toString() ?? 'cdac',
    );
  }
}

class EventRepository {
  final ApiClient client;

  EventRepository({ApiClient? client}) : client = client ?? ApiClient();

  Future<EventSummary?> fetchEventInfo() async {
    try {
      final response = await client.get(ApiConstants.eventEndpoint);
      if (response is Map<String, dynamic>) {
        return EventSummary.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  Future<List<TechnologyDomainItem>> fetchTechnologyDomains() async {
    try {
      final response = await client.get(ApiConstants.technologyDomainsEndpoint);
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((e) => TechnologyDomainItem.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetches thematic sessions from PostgreSQL database, optionally filtered by user-selected domains.
  Future<List<SessionItem>> fetchThematicSessions({List<String>? domains}) async {
    try {
      final queryParams = <String, String>{};
      if (domains != null && domains.isNotEmpty) {
        queryParams['domains'] = domains.join(',');
      }
      final response = await client.get(
        ApiConstants.thematicSessionsEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((e) => SessionItem.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetches Important Dates and Latest News from the PostgreSQL `important_dates` table.
  Future<List<ImportantDateItem>> fetchImportantDates() async {
    try {
      final response = await client.get(ApiConstants.importantDatesEndpoint);
      if (response is List) {
        final list = response
            .whereType<Map<String, dynamic>>()
            .map((e) => ImportantDateItem.fromJson({
                  ...e,
                  'timeAgo': e['dateLabel'] ?? e['eventDate'] ?? '',
                  'category': 'IMPORTANT DATE',
                  'description': e['title'] ?? '',
                  'displayOrder': e['displayOrder'] ?? 0,
                }))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {}
    return ImportantDatesData.defaultDates;
  }
}

