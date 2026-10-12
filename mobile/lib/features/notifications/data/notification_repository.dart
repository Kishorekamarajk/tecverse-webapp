import '../../../core/constants/api_constants.dart';
import '../../../core/networking/api_client.dart';
import '../domain/notification_item.dart';

class NotificationRepository {
  final ApiClient client;

  NotificationRepository({ApiClient? client}) : client = client ?? ApiClient();

  static final List<NotificationItem> _fallbackNotifications = [
    NotificationItem(
      id: 1,
      title: 'TEC-VERSE 2026 Digital Pass Activated',
      message: 'Your official Digital Event Pass and QR Credential are ready. Present this pass at Gate 2 of Chennai Trade Centre for fast-track badge collection.',
      category: 'ANNOUNCEMENT',
      priority: 'HIGH',
      actionRoute: '/pass',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationItem(
      id: 2,
      title: 'Keynote Schedule & Sessions Live',
      message: 'Explore the newly announced plenary tracks by C-DAC, SAMEER, and C-MET. Check the schedule to bookmark your interested domains.',
      category: 'SCHEDULE',
      priority: 'NORMAL',
      actionRoute: '/schedule',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationItem(
      id: 3,
      title: 'Venue Directions & Transport Guide',
      message: 'The event is hosted at Chennai Trade Centre, Nandambakkam. Free parking and shuttle assistance are available for registered delegates.',
      category: 'UPDATE',
      priority: 'NORMAL',
      actionRoute: '/location',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationItem(
      id: 4,
      title: 'Paper Submission Acceptance Notices Sent',
      message: 'Authors of submitted research papers can check the acceptance status and camera-ready submission guidelines in the Latest News section.',
      category: 'REMINDER',
      priority: 'NORMAL',
      actionRoute: '/news',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// Fetches notifications from the PostgreSQL backend
  Future<List<NotificationItem>> fetchNotifications({String? userRef, String? token}) async {
    try {
      final queryParams = <String, String>{};
      if (userRef != null && userRef.isNotEmpty) {
        queryParams['userRef'] = userRef;
      }
      final response = await client.get(
        ApiConstants.notificationsEndpoint,
        token: token,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response is List) {
        final list = response
            .whereType<Map<String, dynamic>>()
            .map((e) => NotificationItem.fromJson(e))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {}
    return _fallbackNotifications;
  }

  /// Marks a notification as read
  Future<bool> markAsRead(int id, {String? token}) async {
    try {
      await client.post('${ApiConstants.notificationsEndpoint}/$id/read', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Marks all notifications as read
  Future<bool> markAllAsRead({String? token}) async {
    try {
      await client.post('${ApiConstants.notificationsEndpoint}/read-all', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }
}
