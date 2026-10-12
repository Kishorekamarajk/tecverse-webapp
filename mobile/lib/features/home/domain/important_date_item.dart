class ImportantDateItem {
  final int id;
  final String title;
  final String eventDate;
  final String timeAgo;
  final String category;
  final String status;
  final String imageUrl;
  final String description;
  final String? actionUrl;
  final int displayOrder;
  final bool isFeatured;

  const ImportantDateItem({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.timeAgo,
    required this.category,
    required this.status,
    required this.imageUrl,
    required this.description,
    this.actionUrl,
    this.displayOrder = 0,
    this.isFeatured = true,
  });

  factory ImportantDateItem.fromJson(Map<String, dynamic> json) {
    return ImportantDateItem(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title']?.toString() ?? '',
      eventDate: json['eventDate']?.toString() ?? json['event_date']?.toString() ?? '',
      timeAgo: json['timeAgo']?.toString() ?? json['time_ago']?.toString() ?? 'Recent',
      category: json['category']?.toString() ?? 'General',
      status: json['status']?.toString() ?? 'ACTIVE',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? 'assets/images/news_techverse.jpg',
      description: json['description']?.toString() ?? '',
      actionUrl: json['actionUrl']?.toString() ?? json['action_url']?.toString(),
      displayOrder: json['displayOrder'] is int ? json['displayOrder'] : (json['display_order'] is int ? json['display_order'] : 0),
      isFeatured: json['isFeatured'] == true || json['is_featured'] == true || json['isFeatured'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'eventDate': eventDate,
      'timeAgo': timeAgo,
      'category': category,
      'status': status,
      'imageUrl': imageUrl,
      'description': description,
      'actionUrl': actionUrl,
      'displayOrder': displayOrder,
      'isFeatured': isFeatured,
    };
  }
}
