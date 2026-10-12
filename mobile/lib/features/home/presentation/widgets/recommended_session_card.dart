import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animation_utils.dart';

class SessionItem {
  final String title;
  final String time;
  final String hall;
  final String domain;
  final String speaker;
  final bool isHighlight;
  final String? description;
  final String day; // Day 1 or Day 2
  final String duration;
  final String sessionType; // 'PLENARY', 'TECHNICAL SESSION', etc.
  final String? imagePath;

  const SessionItem({
    required this.title,
    required this.time,
    required this.hall,
    required this.domain,
    required this.speaker,
    this.isHighlight = false,
    this.description,
    this.day = 'Day 1',
    this.duration = '75 min',
    this.sessionType = 'TECHNICAL SESSION',
    this.imagePath,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) {
    return SessionItem(
      title: json['title']?.toString() ?? 'Session',
      time: json['timeLabel']?.toString() ?? json['time']?.toString() ?? '09:30 AM – 10:45 AM',
      hall: json['hall']?.toString() ?? 'Auditorium 1',
      domain: json['domain']?.toString() ?? 'General',
      speaker: json['speaker']?.toString() ?? '',
      isHighlight: json['isHighlight'] == true || json['highlighted'] == true,
      description: json['description']?.toString(),
      day: json['dayLabel']?.toString() ?? json['day']?.toString() ?? 'Day 1',
      duration: json['duration']?.toString() ?? '75 min',
      sessionType: json['sessionType']?.toString() ?? (json['isHighlight'] == true ? 'PLENARY' : 'TECHNICAL SESSION'),
      imagePath: json['imagePath']?.toString(),
    );
  }
}

/// Helper color and icon styling for technology domains
class DomainStyleHelper {
  static Color getBadgeBgColor(String domain) {
    final d = domain.toLowerCase();
    if (d.contains('ai') || d.contains('supercomputing')) return const Color(0xFFFFF1EC);
    if (d.contains('quantum')) return const Color(0xFFF3E8FF);
    if (d.contains('5g') || d.contains('6g') || d.contains('network')) return const Color(0xFFEFF6FF);
    if (d.contains('green') || d.contains('power') || d.contains('energy')) return const Color(0xFFECFDF5);
    if (d.contains('cyber')) return const Color(0xFFF0F9FF);
    if (d.contains('semiconductor') || d.contains('vlsi')) return const Color(0xFFFFF7ED);
    if (d.contains('photonics') || d.contains('sensor')) return const Color(0xFFFEFCE8);
    if (d.contains('iot') || d.contains('smart')) return const Color(0xFFECFEFF);
    if (d.contains('materials')) return const Color(0xFFEEF2FF);
    if (d.contains('robotics') || d.contains('automation')) return const Color(0xFFF0FDFA);
    return const Color(0xFFF1F5F9);
  }

  static Color getBadgeTextColor(String domain) {
    final d = domain.toLowerCase();
    if (d.contains('ai') || d.contains('supercomputing')) return const Color(0xFFEA580C);
    if (d.contains('quantum')) return const Color(0xFF7E22CE);
    if (d.contains('5g') || d.contains('6g') || d.contains('network')) return const Color(0xFF2563EB);
    if (d.contains('green') || d.contains('power') || d.contains('energy')) return const Color(0xFF059669);
    if (d.contains('cyber')) return const Color(0xFF0284C7);
    if (d.contains('semiconductor') || d.contains('vlsi')) return const Color(0xFFC2410C);
    if (d.contains('photonics') || d.contains('sensor')) return const Color(0xFFCA8A04);
    if (d.contains('iot') || d.contains('smart')) return const Color(0xFF0891B2);
    if (d.contains('materials')) return const Color(0xFF4F46E5);
    if (d.contains('robotics') || d.contains('automation')) return const Color(0xFF0D9488);
    return const Color(0xFF475569);
  }

  static IconData getDomainIcon(String domain) {
    final d = domain.toLowerCase();
    if (d.contains('all')) return Icons.grid_view_rounded;
    if (d.contains('5g') || d.contains('6g') || d.contains('network')) return Icons.cell_tower_rounded;
    if (d.contains('ai') || d.contains('supercomputing')) return Icons.memory_rounded;
    if (d.contains('green') || d.contains('power') || d.contains('energy')) return Icons.eco_rounded;
    if (d.contains('quantum')) return Icons.hub_rounded;
    if (d.contains('cyber')) return Icons.shield_outlined;
    if (d.contains('semiconductor') || d.contains('vlsi')) return Icons.developer_board_rounded;
    if (d.contains('photonics') || d.contains('sensor')) return Icons.lightbulb_outline_rounded;
    if (d.contains('iot') || d.contains('smart')) return Icons.router_rounded;
    if (d.contains('materials')) return Icons.layers_outlined;
    if (d.contains('robotics') || d.contains('automation')) return Icons.precision_manufacturing_rounded;
    return Icons.interests_rounded;
  }

  static String getDefaultImagePath(String domain) {
    final d = domain.toLowerCase();
    if (d.contains('ai') || d.contains('supercomputing')) return 'assets/images/event1.jpg';
    if (d.contains('quantum')) return 'assets/images/event2.jpg';
    if (d.contains('5g') || d.contains('6g') || d.contains('network')) return 'assets/images/event3.jpg';
    if (d.contains('green') || d.contains('power') || d.contains('energy')) return 'assets/images/event4.jpg';
    if (d.contains('semiconductor') || d.contains('vlsi')) return 'assets/images/event5.jpg';
    if (d.contains('cyber')) return 'assets/images/news_techverse.jpg';
    if (d.contains('robotics') || d.contains('automation')) return 'assets/images/cdactexh.png';
    return 'assets/images/event1.jpg';
  }
}

/// Premium Technology Conference Session Card.
/// Matches the exact pixel-perfect design in the TEC-VERSE 2026 Programme interface.
class RecommendedSessionCard extends StatefulWidget {
  final SessionItem session;
  final VoidCallback? onAddToSchedule;
  final VoidCallback? onTap;
  final bool isBookmarked;

  const RecommendedSessionCard({
    super.key,
    required this.session,
    this.onAddToSchedule,
    this.onTap,
    this.isBookmarked = false,
  });

  @override
  State<RecommendedSessionCard> createState() => _RecommendedSessionCardState();
}

class _RecommendedSessionCardState extends State<RecommendedSessionCard> {
  late bool _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.isBookmarked;
  }

  @override
  void didUpdateWidget(covariant RecommendedSessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBookmarked != widget.isBookmarked) {
      _bookmarked = widget.isBookmarked;
    }
  }

  void _toggleBookmark() {
    setState(() => _bookmarked = !_bookmarked);
    widget.onAddToSchedule?.call();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final domainBg = DomainStyleHelper.getBadgeBgColor(session.domain);
    final domainText = DomainStyleHelper.getBadgeTextColor(session.domain);
    final isPlenary = session.sessionType.toUpperCase() == 'PLENARY' || session.isHighlight;
    final imagePath = session.imagePath ?? DomainStyleHelper.getDefaultImagePath(session.domain);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleOnPress(
        onTap: widget.onTap,
        scaleFactor: 0.985,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: session.isHighlight
                  ? const Color(0xFFFFD8CC)
                  : const Color(0xFFE5E7EB),
              width: session.isHighlight ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF102A43).withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. Left Thumbnail ───
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 78,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              DomainStyleHelper.getDomainIcon(session.domain),
                              color: AppColors.primaryOrange,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      // High-tech subtle bottom gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ─── 2. Right Content ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Badges & Featured Tag
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Domain Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: domainBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            session.domain.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: domainText,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        // Session Type Badge (PLENARY / TECHNICAL SESSION)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isPlenary ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            (isPlenary ? 'PLENARY' : session.sessionType).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isPlenary ? const Color(0xFFB45309) : const Color(0xFF2563EB),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        // Featured Session Tag
                        if (session.isHighlight)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star_rounded, size: 12, color: Color(0xFFEA580C)),
                              SizedBox(width: 2),
                              Text(
                                'Featured Session',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Row 2: Title
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Row 3: Time & Duration
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFF97316)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            session.time,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                        const SizedBox(width: 4),
                        const Icon(Icons.hourglass_empty_rounded, size: 12, color: Color(0xFFF97316)),
                        const SizedBox(width: 3),
                        Text(
                          session.duration,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Row 4: Speaker, Hall & Action Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Speaker & Hall details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (session.speaker.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFFF97316)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        session.speaker,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFF97316)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      session.hall,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Action Button (+ Add / Added)
                        InkWell(
                          onTap: _toggleBookmark,
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _bookmarked ? const Color(0xFF059669) : const Color(0xFFF97316),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: (_bookmarked ? const Color(0xFF059669) : const Color(0xFFF97316))
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _bookmarked ? Icons.check_rounded : Icons.add_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _bookmarked ? 'Added' : 'Add',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
