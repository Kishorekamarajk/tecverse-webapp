import '../../../core/constants/api_constants.dart';
import '../../../core/networking/api_client.dart';
import '../domain/faq_item.dart';

/// Repository responsible for loading FAQ items from backend `faq_items` database.
class FaqRepository {
  final ApiClient _client;

  FaqRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches all active FAQ items directly from the PostgreSQL database table `faq_items`
  Future<List<FaqItem>> fetchFaqItems() async {
    try {
      final response = await _client.get(ApiConstants.faqEndpoint);
      List? listData;

      if (response is List) {
        listData = response;
      } else if (response is Map) {
        if (response['data'] is List) {
          listData = response['data'] as List;
        } else if (response['faqs'] is List) {
          listData = response['faqs'] as List;
        } else if (response['faq_items'] is List) {
          listData = response['faq_items'] as List;
        }
      }

      if (listData != null) {
        final items = listData
            .whereType<Map<String, dynamic>>()
            .map((json) => FaqItem.fromJson(json))
            .toList();

        items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return items;
      }
    } catch (e) {
      // Backend request error
    }
    return [];
  }

  /// Searches FAQs by query string directly in PostgreSQL database
  Future<List<FaqItem>> searchFaq(String query) async {
    try {
      final response = await _client.get('${ApiConstants.faqEndpoint}/search?query=${Uri.encodeComponent(query)}');
      List? listData;

      if (response is List) {
        listData = response;
      } else if (response is Map && response['data'] is List) {
        listData = response['data'] as List;
      }

      if (listData != null) {
        return listData
            .whereType<Map<String, dynamic>>()
            .map((json) => FaqItem.fromJson(json))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
