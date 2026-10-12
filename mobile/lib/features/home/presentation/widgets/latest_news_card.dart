import 'package:flutter/material.dart';
import '../../../../core/widgets/animation_utils.dart';
import '../../domain/important_date_item.dart';

/// Latest News / Important Date Card matching reference design.
class LatestNewsCard extends StatelessWidget {
  final ImportantDateItem item;
  final VoidCallback onTap;

  const LatestNewsCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnPress(
      onTap: onTap,
      scaleFactor: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF1E6DF),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF102A43).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Image Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 85,
                height: 58,
                child: _buildImage(item.imageUrl),
              ),
            ),

            const SizedBox(width: 12),

            // Middle Title & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF102A43),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (item.category.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Right Chevron Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackImage(),
      );
    }

    return Image.asset(
      url.isNotEmpty ? url : 'assets/images/event1.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFF102A43),
      child: const Center(
        child: Icon(
          Icons.newspaper_rounded,
          color: Colors.white70,
          size: 24,
        ),
      ),
    );
  }
}
