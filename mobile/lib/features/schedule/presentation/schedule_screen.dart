import 'package:flutter/material.dart';
import '../data/schedule_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────────────────────────────────────

enum EventCategory {
  registration,
  ceremony,
  keynote,
  cultural,
  networking,
  lunch,
  tea,
  stall,
  mou,
  welcome,
  general,
}

class ConferenceEvent {
  final String time;        // e.g. "09:00 AM"
  final String endTime;     // e.g. "10:00 AM"
  final String title;
  final String subtitle;
  final EventCategory category;
  final bool isHighlight;
  final String? badgeLabel;
  final String? imagePath;
  final String hall;

  const ConferenceEvent({
    required this.time,
    required this.endTime,
    required this.title,
    this.subtitle = 'Conference session and proceedings.',
    required this.category,
    this.isHighlight = false,
    this.badgeLabel,
    this.imagePath,
    this.hall = 'Auditorium 1 • Chennai Trade Centre',
  });

  /// Returns a TimeOfDay parsed from the "hh:mm AM/PM" string for active detection.
  TimeOfDay get startTod {
    final parts = time.split(' ');
    final hm = parts[0].split(':');
    int hour = int.parse(hm[0]);
    final int minute = int.parse(hm[1]);
    final bool isPm = parts[1].toUpperCase() == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  TimeOfDay get endTod {
    final parts = endTime.split(' ');
    final hm = parts[0].split(':');
    int hour = int.parse(hm[0]);
    final int minute = int.parse(hm[1]);
    final bool isPm = parts[1].toUpperCase() == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Catalog
// ─────────────────────────────────────────────────────────────────────────────

const List<ConferenceEvent> _day1Events = [
  ConferenceEvent(
    time: '09:00 AM',
    endTime: '10:00 AM',
    title: 'Registration',
    subtitle: 'Delegate registration and event pass collection.',
    category: EventCategory.registration,
    imagePath: 'assets/images/event1.jpg',
  ),
  ConferenceEvent(
    time: '10:00 AM',
    endTime: '10:30 AM',
    title: 'Arrival of Guests',
    subtitle: 'Welcome and guest arrival at the venue.',
    category: EventCategory.welcome,
    imagePath: 'assets/images/event2.jpg',
  ),
  ConferenceEvent(
    time: '10:35 AM',
    endTime: '10:45 AM',
    title: 'Inaugural Ceremony (Lamp Lighting)',
    subtitle: 'Auspicious lamp lighting & ceremonial inauguration.',
    category: EventCategory.ceremony,
    isHighlight: true,
    badgeLabel: 'Featured Event',
    imagePath: 'assets/images/event3.jpg',
  ),
  ConferenceEvent(
    time: '10:45 AM',
    endTime: '10:50 AM',
    title: 'Tamil Thai Vazhthu',
    subtitle: 'Invocation and cultural tribute.',
    category: EventCategory.cultural,
    imagePath: 'assets/images/event4.jpg',
  ),
  ConferenceEvent(
    time: '10:50 AM',
    endTime: '11:00 AM',
    title: 'Welcome Address',
    subtitle: 'Opening remarks by the event convener.',
    category: EventCategory.welcome,
    imagePath: 'assets/images/stillout.jpg',
  ),
  ConferenceEvent(
    time: '11:00 AM',
    endTime: '11:30 AM',
    title: 'Keynote Address',
    subtitle: 'Keynote address by dignitaries and MeitY leadership.',
    category: EventCategory.keynote,
    isHighlight: true,
    badgeLabel: 'Keynote',
    imagePath: 'assets/images/news_techverse.jpg',
  ),
  ConferenceEvent(
    time: '11:30 AM',
    endTime: '12:30 PM',
    title: 'Product Launch / IoA / MoU',
    subtitle: 'Commercialization of indigenous deep-tech solutions.',
    category: EventCategory.mou,
    isHighlight: true,
    badgeLabel: 'Strategic MoU',
    imagePath: 'assets/images/cdactexh.png',
  ),
  ConferenceEvent(
    time: '12:30 PM',
    endTime: '01:30 PM',
    title: 'Stall Visit by Chief Guest',
    subtitle: 'Dignitaries tour indigenous innovation exhibition.',
    category: EventCategory.stall,
    imagePath: 'assets/images/stall-3x3.png',
  ),
  ConferenceEvent(
    time: '01:30 PM',
    endTime: '02:30 PM',
    title: 'Lunch Break',
    subtitle: 'Networking luncheon at Dining Pavilion.',
    category: EventCategory.lunch,
    imagePath: 'assets/images/event1.jpg',
  ),
  ConferenceEvent(
    time: '04:30 PM',
    endTime: '05:00 PM',
    title: 'High Tea',
    subtitle: 'Evening refreshments and informal interactions.',
    category: EventCategory.tea,
    imagePath: 'assets/images/event2.jpg',
  ),
  ConferenceEvent(
    time: '06:00 PM',
    endTime: '08:00 PM',
    title: 'Cultural Program',
    subtitle: 'Classical music, traditional arts and cultural evening.',
    category: EventCategory.cultural,
    isHighlight: true,
    badgeLabel: 'Cultural Gala',
    imagePath: 'assets/images/event4.jpg',
  ),
  ConferenceEvent(
    time: '08:00 PM',
    endTime: '09:30 PM',
    title: 'Dinner',
    subtitle: 'Gala dinner and networking reception.',
    category: EventCategory.lunch,
    imagePath: 'assets/images/event5.jpg',
  ),
];

const List<ConferenceEvent> _day2Events = [
  ConferenceEvent(
    time: '09:00 AM',
    endTime: '10:00 AM',
    title: 'Registration',
    subtitle: 'Day 2 registration and badge verification.',
    category: EventCategory.registration,
    imagePath: 'assets/images/event1.jpg',
  ),
  ConferenceEvent(
    time: '10:00 AM',
    endTime: '10:15 AM',
    title: 'Welcome Address',
    subtitle: 'Opening remarks for Day 2 thematic symposiums.',
    category: EventCategory.welcome,
    isHighlight: true,
    imagePath: 'assets/images/stillout.jpg',
  ),
  ConferenceEvent(
    time: '10:15 AM',
    endTime: '11:15 AM',
    title: 'Keynote Address by Chief Guest',
    subtitle: 'Strategic roadmaps in semiconductor and quantum missions.',
    category: EventCategory.keynote,
    isHighlight: true,
    badgeLabel: 'Keynote',
    imagePath: 'assets/images/news_techverse.jpg',
  ),
  ConferenceEvent(
    time: '11:30 AM',
    endTime: '11:45 AM',
    title: 'High Tea',
    subtitle: 'Morning tea and informal networking.',
    category: EventCategory.tea,
    imagePath: 'assets/images/event2.jpg',
  ),
  ConferenceEvent(
    time: '11:45 AM',
    endTime: '01:30 PM',
    title: 'Stall Visit by Students & Startups',
    subtitle: 'Interactive technology demonstrations and startup expo.',
    category: EventCategory.stall,
    imagePath: 'assets/images/stall-6x6.png',
  ),
  ConferenceEvent(
    time: '01:30 PM',
    endTime: '02:30 PM',
    title: 'Lunch Break',
    subtitle: 'Networking luncheon at Dining Pavilion.',
    category: EventCategory.lunch,
    imagePath: 'assets/images/event3.jpg',
  ),
  ConferenceEvent(
    time: '03:00 PM',
    endTime: '03:40 PM',
    title: 'MoU Signing Inauguration',
    subtitle: 'Bilateral MoUs and industry technology transfers.',
    category: EventCategory.mou,
    isHighlight: true,
    badgeLabel: 'MoU Signing',
    imagePath: 'assets/images/cdactexh.png',
  ),
  ConferenceEvent(
    time: '04:30 PM',
    endTime: '05:30 PM',
    title: 'Valedictory & Awards Ceremony',
    subtitle: 'Honoring innovators, researchers and conclave wrap-up.',
    category: EventCategory.ceremony,
    isHighlight: true,
    badgeLabel: 'Valedictory',
    imagePath: 'assets/images/event5.jpg',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Category Styling Helpers
// ─────────────────────────────────────────────────────────────────────────────

IconData _iconFor(EventCategory cat) {
  switch (cat) {
    case EventCategory.registration:
      return Icons.event_available_rounded;
    case EventCategory.keynote:
      return Icons.mic_rounded;
    case EventCategory.cultural:
      return Icons.music_note_rounded;
    case EventCategory.lunch:
      return Icons.restaurant_rounded;
    case EventCategory.tea:
      return Icons.local_cafe_rounded;
    case EventCategory.stall:
      return Icons.storefront_rounded;
    case EventCategory.mou:
      return Icons.handshake_rounded;
    case EventCategory.ceremony:
      return Icons.stars_rounded;
    case EventCategory.welcome:
      return Icons.groups_rounded;
    case EventCategory.networking:
      return Icons.hub_rounded;
    case EventCategory.general:
      return Icons.play_circle_outline_rounded;
  }
}

Color _accentFor(EventCategory cat) {
  switch (cat) {
    case EventCategory.registration:
      return const Color(0xFF2563EB); // Royal Blue
    case EventCategory.welcome:
      return const Color(0xFFEA580C); // Orange
    case EventCategory.ceremony:
      return const Color(0xFF0D9488); // Teal / Green
    case EventCategory.cultural:
      return const Color(0xFFEC4899); // Pink / Magenta
    case EventCategory.keynote:
      return const Color(0xFF0284C7); // Sky Blue
    case EventCategory.mou:
      return const Color(0xFFEA580C); // Orange
    case EventCategory.stall:
      return const Color(0xFF3B82F6); // Blue
    case EventCategory.lunch:
      return const Color(0xFF10B981); // Emerald
    case EventCategory.tea:
      return const Color(0xFFD97706); // Amber
    case EventCategory.networking:
      return const Color(0xFF6366F1); // Indigo
    case EventCategory.general:
      return const Color(0xFF8B5CF6); // Purple
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ScheduleScreen({super.key, this.onBackPressed});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDay = 0; // 0 = Day 1, 1 = Day 2
  String _selectedFilter = 'ALL';
  final Set<String> _bookmarkedTitles = {};

  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  bool _isLoading = false;
  List<ConferenceEvent> _liveDay1Events = [];
  List<ConferenceEvent> _liveDay2Events = [];

  // Dates for active-session detection (Nov 2026)
  static final _day1Date = DateTime(2026, 11, 26);
  static final _day2Date = DateTime(2026, 11, 27);

  @override
  void initState() {
    super.initState();
    // Auto-select the current conference day if today matches
    final today = DateTime.now();
    if (today.year == _day1Date.year &&
        today.month == _day1Date.month &&
        today.day == _day1Date.day) {
      _selectedDay = 0;
    } else if (today.year == _day2Date.year &&
        today.month == _day2Date.month &&
        today.day == _day2Date.day) {
      _selectedDay = 1;
    }

    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final grouped = await _scheduleRepository.fetchScheduleEvents();
      if (mounted) {
        setState(() {
          if (grouped.containsKey(1) && grouped[1]!.isNotEmpty) {
            _liveDay1Events = grouped[1]!;
          }
          if (grouped.containsKey(2) && grouped[2]!.isNotEmpty) {
            _liveDay2Events = grouped[2]!;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ConferenceEvent> get _currentEvents {
    if (_selectedDay == 0) {
      return _liveDay1Events.isNotEmpty ? _liveDay1Events : _day1Events;
    } else {
      return _liveDay2Events.isNotEmpty ? _liveDay2Events : _day2Events;
    }
  }

  List<ConferenceEvent> get _filteredEvents {
    final list = _currentEvents;
    if (_selectedFilter == 'ALL') return list;
    if (_selectedFilter == 'KEYNOTE') {
      return list.where((e) => e.category == EventCategory.keynote || e.isHighlight).toList();
    }
    if (_selectedFilter == 'CEREMONY') {
      return list.where((e) => e.category == EventCategory.ceremony || e.category == EventCategory.welcome).toList();
    }
    if (_selectedFilter == 'TECHNICAL') {
      return list.where((e) => e.category == EventCategory.mou || e.category == EventCategory.stall || e.category == EventCategory.general).toList();
    }
    if (_selectedFilter == 'BREAKS') {
      return list.where((e) => e.category == EventCategory.lunch || e.category == EventCategory.tea || e.category == EventCategory.cultural).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 1. Header Banner matching screenshot ───
            SliverToBoxAdapter(
              child: _buildHeaderBanner(context),
            ),

            // ─── 2. Day Selector Cards (Day 01 vs Day 02) ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDayCard(
                        dayIndex: 0,
                        title: 'DAY 01',
                        date: '26 November 2026',
                        isSelected: _selectedDay == 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDayCard(
                        dayIndex: 1,
                        title: 'DAY 02',
                        date: '27 November 2026',
                        isSelected: _selectedDay == 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 3. Event Category Filter Chips ───
            SliverToBoxAdapter(
              child: _buildCategoryFilterChips(),
            ),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    color: Color(0xFFF97316),
                    minHeight: 2,
                  ),
                ),
              ),

            // ─── 4. Timeline Schedule Content ───
            if (filteredEvents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = filteredEvents[index];
                      final isLast = index == filteredEvents.length - 1;
                      final isFirst = index == 0;

                      return _buildTimelineItem(
                        event: event,
                        isFirst: isFirst,
                        isLast: isLast,
                        onTap: () => _showEventDetails(context, event),
                      );
                    },
                    childCount: filteredEvents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 1. Top Header Banner with Panoramic Backdrop & Floating Days Pill
  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9F5),
      ),
      child: Stack(
        children: [
          // Background graphic illustration
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.95,
              child: Image.asset(
                'assets/images/conbanner.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/scanner_banner.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Gradient wash for seamless text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF9F5),
                    const Color(0xFFFFF9F5).withValues(alpha: 0.94),
                    const Color(0xFFFFF9F5).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.48, 0.78, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Back button + Floating "2 Days to go" pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Circular White Back Button
                    GestureDetector(
                      onTap: () {
                        if (widget.onBackPressed != null) {
                          widget.onBackPressed!();
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // Floating 2 Days To Go Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD4BE), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                '2 Days',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEA580C),
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'to go',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tag
                const Text(
                  'CONFERENCE PROGRAMME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF97316),
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 2),

                // Title: TEC-VERSE 2026
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'TEC-VERSE ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.3,
                        ),
                      ),
                      TextSpan(
                        text: '2026',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF97316),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Dates & Location
                Row(
                  children: const [
                    Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFFF97316)),
                    SizedBox(width: 5),
                    Text(
                      '26 – 27 November 2026',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                Row(
                  children: const [
                    Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFF97316)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Nandambakkam, Tamil Nadu 600089',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  /// 2. Day Selector Cards (DAY 01 vs DAY 02)
  Widget _buildDayCard({
    required int dayIndex,
    required String title,
    required String date,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedDay = dayIndex),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFDBA74) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF6B00).withValues(alpha: 0.10)
                  : const Color(0xFF102A43).withValues(alpha: 0.03),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 22,
              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF334155),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Horizontal Category Chips
  Widget _buildCategoryFilterChips() {
    final filters = [
      {'id': 'ALL', 'label': 'All Events', 'icon': Icons.grid_view_rounded},
      {'id': 'KEYNOTE', 'label': 'Keynotes & Talks', 'icon': Icons.mic_rounded},
      {'id': 'CEREMONY', 'label': 'Ceremony', 'icon': Icons.people_alt_rounded},
      {'id': 'TECHNICAL', 'label': 'Technical Sessions', 'icon': Icons.layers_rounded},
      {'id': 'BREAKS', 'label': 'Breaks & Cultural', 'icon': Icons.local_cafe_rounded},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['id'];
          final icon = f['icon'] as IconData;

          return InkWell(
            onTap: () => setState(() => _selectedFilter = f['id'] as String),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 4. Timeline Row Item matching screenshot
  Widget _buildTimelineItem({
    required ConferenceEvent event,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    final accent = _accentFor(event.category);
    final imagePath = event.imagePath ?? 'assets/images/event1.jpg';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timeline node and vertical connector
          SizedBox(
            width: 38,
            child: Column(
              children: [
                // Circular Colored Icon Node
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _iconFor(event.category),
                    size: 16,
                    color: Colors.white,
                  ),
                ),

                // Vertical Connector Line
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.6),
                              const Color(0xFFCBD5E1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right Event Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: event.isHighlight ? const Color(0xFFFFD4BE) : const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF102A43).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${event.time} – ${event.endTime}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // Title
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            // Subtitle
                            Text(
                              event.subtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Badges if highlighted
                            if (event.isHighlight && event.badgeLabel != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: event.badgeLabel == 'Keynote'
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFFFF1EC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      event.badgeLabel == 'Keynote' ? Icons.mic_rounded : Icons.star_rounded,
                                      size: 11,
                                      color: event.badgeLabel == 'Keynote'
                                          ? const Color(0xFF0284C7)
                                          : const Color(0xFFEA580C),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      event.badgeLabel!,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: event.badgeLabel == 'Keynote'
                                            ? const Color(0xFF0284C7)
                                            : const Color(0xFFEA580C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Thumbnail image + Chevron arrow
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 82,
                          height: 56,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.15),
                                  ),
                                  child: Icon(_iconFor(event.category), color: accent, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.event_busy_rounded, size: 42, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No events found for this filter',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, ConferenceEvent event) {
    final accent = _accentFor(event.category);
    final isBookmarked = _bookmarkedTitles.contains(event.title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.category.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  if (event.badgeLabel != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1EC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.badgeLabel!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFF97316)),
                  const SizedBox(width: 6),
                  Text(
                    '${event.time} – ${event.endTime}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFF97316)),
                  const SizedBox(width: 6),
                  Text(
                    event.hall,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 10),
              const Text(
                'Event Overview',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                event.subtitle,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  height: 1.45,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_bookmarkedTitles.contains(event.title)) {
                            _bookmarkedTitles.remove(event.title);
                          } else {
                            _bookmarkedTitles.add(event.title);
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                        size: 16,
                      ),
                      label: Text(isBookmarked ? 'Saved to Schedule' : 'Add to My Schedule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                        side: const BorderSide(color: Color(0xFFFFD4BE)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
