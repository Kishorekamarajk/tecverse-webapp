import 'package:flutter/material.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animation_utils.dart';
import '../../data/notification_repository.dart';
import '../../domain/notification_item.dart';

class NotificationsSheet extends StatefulWidget {
  final String? userRef;

  const NotificationsSheet({super.key, this.userRef});

  static Future<void> show(BuildContext context, {String? userRef}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationsSheet(userRef: userRef),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final NotificationRepository _repository = NotificationRepository();
  final TokenStorage _tokenStorage = SecureTokenStorageImpl();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, UNREAD, ANNOUNCEMENT, SCHEDULE

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final token = await _tokenStorage.getAccessToken();
    final items = await _repository.fetchNotifications(userRef: widget.userRef, token: token);
    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.isRead) return;
    setState(() {
      _notifications = _notifications.map((n) {
        if (n.id == item.id) return n.copyWith(isRead: true);
        return n;
      }).toList();
    });
    await _repository.markAsRead(item.id, token: await _tokenStorage.getAccessToken());
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    await _repository.markAllAsRead(token: await _tokenStorage.getAccessToken());
  }

  void _handleAction(NotificationItem item) {
    _markAsRead(item);
    if (item.actionRoute != null && item.actionRoute!.isNotEmpty) {
      Navigator.pop(context);
      final route = item.actionRoute!;
      if (route == '/pass' || route == '/schedule' || route == '/sessions') {
        Navigator.of(context).pushNamed(route);
      }
    }
  }

  List<NotificationItem> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'UNREAD':
        return _notifications.where((n) => !n.isRead).toList();
      case 'ANNOUNCEMENT':
        return _notifications.where((n) => n.category == 'ANNOUNCEMENT').toList();
      case 'SCHEDULE':
        return _notifications.where((n) => n.category == 'SCHEDULE').toList();
      case 'ALL':
      default:
        return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Notifications',
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '$_unreadCount new',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllAsRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Mark all read',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.cyanAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),

          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All (${_notifications.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('UNREAD', 'Unread ($_unreadCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ANNOUNCEMENT', 'Announcements'),
                  const SizedBox(width: 8),
                  _buildFilterChip('SCHEDULE', 'Schedule'),
                ],
              ),
            ),
          ),

          const Divider(height: 16, color: AppColors.borderSubtle),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                      strokeWidth: 2.5,
                    ),
                  )
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: AppColors.primaryOrange,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: _filteredNotifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final item = _filteredNotifications[idx];
                            return _buildNotificationCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange.withValues(alpha: 0.6)
                : AppColors.borderSubtle,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return ScaleOnPress(
      onTap: () => _handleAction(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.surfaceCard
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? AppColors.borderSubtle
                : item.categoryColor.withValues(alpha: 0.35),
            width: item.isRead ? 0.8 : 1.2,
          ),
          boxShadow: item.isRead
              ? null
              : [
                  BoxShadow(
                    color: item.categoryColor.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Square
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: item.categoryColor.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Icon(
                item.icon,
                color: item.categoryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Category Badge + Time Ago + Unread Indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: item.categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category,
                          style: AppTypography.metaTag.copyWith(
                            fontSize: 9,
                            color: item.categoryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${item.timeAgoFormatted}',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (!item.isRead)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    item.title,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 13.5,
                      fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Message
                  Text(
                    item.message,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  // Action hint
                  if (item.actionRoute != null && item.actionRoute!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tap to view',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyanAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: AppColors.cyanAccent,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 26,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No Notifications',
              style: AppTypography.headlineMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'You are all caught up for TEC-VERSE 2026.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
