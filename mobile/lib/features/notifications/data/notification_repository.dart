import '../../../core/constants/api_constants.dart';
import '../../../core/networking/api_client.dart';
import '../domain/notification_item.dart';

class NotificationRepository {
  final ApiClient client;

  NotificationRepository({ApiClient? client}) : client = client ?? ApiClient();

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
    // No invented notifications: an empty list shows the screen's empty state.
    return const [];
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
