import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../authentication/domain/authenticated_user.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../home/data/event_repository.dart';
import '../../home/presentation/interest_selection_dialog.dart';
import '../../home/presentation/widgets/recommended_session_card.dart';

/// Dedicated Technology Sessions & Conference Programme Screen.
/// Matches the exact pixel-perfect design in the reference screenshots.
class SessionsScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final void Function(int)? onNavigateTab;

  const SessionsScreen({
    super.key,
    this.onBackPressed,
    this.onNavigateTab,
  });

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final EventRepository _eventRepository = EventRepository();

  String _searchQuery = '';
  String _selectedDomain = 'All';
  String _selectedDay = 'All';
  String _sortBy = 'Time (Earliest)';
  final Set<String> _bookmarkedTitles = {};

  List<TechnologyDomainItem> _liveDomains = [];

  static const List<String> _availableDomains = [
    'All',
    'AI & Supercomputing',
    'Quantum Technologies',
    'Cybersecurity',
    'Semiconductors & VLSI',
    '5G/6G & Future Networks',
    'Green Tech & Power Electronics',
    'Photonics & Sensors',
    'IoT & Smart Systems',
    'Advanced Materials',
    'Robotics & Automation',
  ];

  // Master Sessions Catalog matching TEC-VERSE 2026 Programme
  static const List<SessionItem> _allSessions = [
    // ─── Day 1 Sessions ───
    SessionItem(
      title: 'Plenary: National AI Mission & PARAM Supercomputing Frontiers',
      time: '09:30 AM – 10:45 AM',
      hall: 'Auditorium 1',
      domain: 'AI & Supercomputing',
      speaker: 'C-DAC HPC Leadership & Team',
      isHighlight: true,
      day: 'Day 1',
      duration: '75 min',
      sessionType: 'PLENARY',
      imagePath: 'assets/images/event1.jpg',
      description: 'Keynote exploration of exascale compute architecture, indigenous PARAM supercomputing clusters, and Sovereign AI infrastructure.',
    ),
    SessionItem(
      title: 'National Quantum Mission: Quantum Communications & QKD',
      time: '11:15 AM – 12:30 PM',
      hall: 'Auditorium 1',
      domain: 'Quantum Technologies',
      speaker: 'Experts from Academia & Industry',
      isHighlight: false,
      day: 'Day 1',
      duration: '75 min',
      sessionType: 'PLENARY',
      imagePath: 'assets/images/event2.jpg',
      description: 'Quantum key distribution protocols, satellite-based quantum channels, and quantum-safe cryptography deployments across national networks.',
    ),
    SessionItem(
      title: 'Beyond 5G: Architecture, Use Cases and Standardization',
      time: '01:30 PM – 02:30 PM',
      hall: 'Conference Hall A',
      domain: '5G/6G & Future Networks',
      speaker: 'C-DAC Research Team',
      isHighlight: false,
      day: 'Day 1',
      duration: '60 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/event3.jpg',
      description: 'Open RAN architectures, sub-THz wave propagation models, and satellite-terrestrial integrated networks.',
    ),
    SessionItem(
      title: 'Sustainable Energy Systems for a Net Zero Future',
      time: '02:45 PM – 03:45 PM',
      hall: 'Conference Hall B',
      domain: 'Green Tech & Power Electronics',
      speaker: 'Industry Experts',
      isHighlight: false,
      day: 'Day 1',
      duration: '60 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/event4.jpg',
      description: 'High-frequency radar dielectric substrates, GaN power amplifiers, solar PV optimization, and specialized magnetics.',
    ),
    SessionItem(
      title: 'Critical Information Infrastructure & Zero Trust Defense',
      time: '04:00 PM – 05:00 PM',
      hall: 'Hall 1B',
      domain: 'Cybersecurity',
      speaker: 'CERT-In / MeitY Security',
      isHighlight: false,
      day: 'Day 1',
      duration: '60 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/news_techverse.jpg',
      description: 'Deep dive into national threat telemetry, automated SIEM response, and defense architectures for strategic sectors.',
    ),
    SessionItem(
      title: 'India Semiconductor Mission: Indigenous Silicon & RISC-V VEGA',
      time: '05:15 PM – 06:15 PM',
      hall: 'Hall 2B',
      domain: 'Semiconductors & VLSI',
      speaker: 'C-DAC Microprocessor Group',
      isHighlight: true,
      day: 'Day 1',
      duration: '60 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/event5.jpg',
      description: 'Architectural roadmap for VEGA series 64-bit processors, custom ASIC fabrication, and indigenous packaging.',
    ),

    // ─── Day 2 Sessions ───
    SessionItem(
      title: 'Autonomous Robotics & Edge AI in Industrial Automation',
      time: '10:00 AM – 11:15 AM',
      hall: 'Hall 2A',
      domain: 'Robotics & Automation',
      speaker: 'Robotics R&D Lab & ARTPARK',
      isHighlight: true,
      day: 'Day 2',
      duration: '75 min',
      sessionType: 'PLENARY',
      imagePath: 'assets/images/cdactexh.png',
      description: 'Edge computer vision inference for real-time cobot manipulation and autonomous mobile robots (AMRs).',
    ),
    SessionItem(
      title: 'Smart City IoT Sensor Grids & LPWAN Architecture',
      time: '11:30 AM – 12:45 PM',
      hall: 'Hall 1B',
      domain: 'IoT & Smart Systems',
      speaker: 'Smart Cities Mission & C-DAC',
      isHighlight: false,
      day: 'Day 2',
      duration: '75 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/event1.jpg',
      description: 'Large-scale urban environmental sensor networks with edge aggregation and standard oneM2M interoperability.',
    ),
    SessionItem(
      title: 'Integrated Photonics, LiDAR & Optical Sensor Networks',
      time: '02:00 PM – 03:15 PM',
      hall: 'Hall 3',
      domain: 'Photonics & Sensors',
      speaker: 'SAMEER & CEERI Scientists',
      isHighlight: false,
      day: 'Day 2',
      duration: '75 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/event2.jpg',
      description: 'Silicon photonics transceivers, solid-state LiDAR beamforming, and fiber-optic distributed sensing.',
    ),
    SessionItem(
      title: 'Graphene & 2D Nanomaterials for Next-Gen Energy Storage',
      time: '03:30 PM – 04:45 PM',
      hall: 'Hall 1A',
      domain: 'Advanced Materials',
      speaker: 'C-MET Advanced Materials Group',
      isHighlight: false,
      day: 'Day 2',
      duration: '75 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/event3.jpg',
      description: 'Supercapacitor electrodes, solid-state electrolytes, and high-density sodium-ion chemistry.',
    ),
    SessionItem(
      title: 'E-Waste Recycling & Critical Rare Earth Extraction',
      time: '05:00 PM – 06:00 PM',
      hall: 'Hall 3',
      domain: 'Green Tech & Power Electronics',
      speaker: 'C-MET Research Team',
      isHighlight: false,
      day: 'Day 2',
      duration: '60 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/event4.jpg',
      description: 'Hydrometallurgical extraction processes for neodymium, cobalt, and lithium from discarded PCB assemblies.',
    ),
    SessionItem(
      title: '5G/6G Testbed Deployments & Indigenous Core Networks',
      time: '06:15 PM – 07:15 PM',
      hall: 'Auditorium 2',
      domain: '5G/6G & Future Networks',
      speaker: 'Telecom Technology Center',
      isHighlight: false,
      day: 'Day 2',
      duration: '60 min',
      sessionType: 'TECHNICAL SESSION',
      imagePath: 'assets/images/event5.jpg',
      description: 'Open RAN architectures, sub-THz wave propagation models, and satellite-terrestrial integrated networks.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveDomains();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveDomains() async {
    try {
      final domains = await _eventRepository.fetchTechnologyDomains();
      if (mounted && domains.isNotEmpty) {
        setState(() => _liveDomains = domains);
      }
    } catch (_) {
      // Fallback to static domains
    }
  }

  List<SessionItem> _getFilteredSessions(List<String> userInterests) {
    var sessions = _allSessions.where((s) {
      // Search Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = s.title.toLowerCase().contains(q);
        final matchDomain = s.domain.toLowerCase().contains(q);
        final matchSpeaker = s.speaker.toLowerCase().contains(q);
        final matchHall = s.hall.toLowerCase().contains(q);
        if (!matchTitle && !matchDomain && !matchSpeaker && !matchHall) {
          return false;
        }
      }

      // Day Filter
      if (_selectedDay != 'All') {
        if (s.day != _selectedDay) return false;
      }

      // Domain Filter
      if (_selectedDomain != 'All') {
        final normSelected = _selectedDomain.toLowerCase().replaceAll('&', 'and').trim();
        final normSession = s.domain.toLowerCase().replaceAll('&', 'and').trim();
        if (!normSession.contains(normSelected) && !normSelected.contains(normSession)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort
    if (_sortBy == 'Time (Earliest)') {
      sessions.sort((a, b) => a.time.compareTo(b.time));
    } else if (_sortBy == 'Time (Latest)') {
      sessions.sort((a, b) => b.time.compareTo(a.time));
    } else if (_sortBy == 'Title (A-Z)') {
      sessions.sort((a, b) => a.title.compareTo(b.title));
    }

    return sessions;
  }

  void _openInterestSelector(BuildContext context, UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InterestSelectionSheet(
        initialSelected: user.interests,
        onSave: (newInterests) async {
          final auth = context.read<AuthController>();
          await auth.updateInterests(newInterests);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Technology domains updated successfully.'),
                backgroundColor: AppColors.surfaceElevated,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final userInterests = user?.interests ?? const ['AI & Supercomputing', 'Cybersecurity'];

    final filteredSessions = _getFilteredSessions(userInterests);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 1. Header Banner ───
            SliverToBoxAdapter(
              child: _buildHeaderBanner(context),
            ),

            // ─── 2. Search Field & Filter Button + Day Filter Chips ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Search Bar & Filter Button
                    Row(
                      children: [
                        // Search Text Field
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF102A43).withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search sessions, speakers, halls...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Filter Button
                        InkWell(
                          onTap: () {
                            if (user != null) {
                              _openInterestSelector(context, user);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFED7AA), width: 1.0),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFFF97316),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Day Filter Tabs (All Days, Day 1, Day 2)
                    Row(
                      children: [
                        _buildDayChip('All', 'All Days'),
                        const SizedBox(width: 8),
                        _buildDayChip('Day 1', 'Day 1 (Nov 26)'),
                        const SizedBox(width: 8),
                        _buildDayChip('Day 2', 'Day 2 (Nov 27)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── 3. Technology Domains Section ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: _buildTechnologyDomainsFilterBar(userInterests),
              ),
            ),

            // ─── 4. Results Count & Sort Dropdown ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${filteredSessions.length} SESSIONS FOUND',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sort by',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          initialValue: _sortBy,
                          onSelected: (val) => setState(() => _sortBy = val),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _sortBy,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF0F172A)),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Time (Earliest)', child: Text('Time (Earliest)')),
                            const PopupMenuItem(value: 'Time (Latest)', child: Text('Time (Latest)')),
                            const PopupMenuItem(value: 'Title (A-Z)', child: Text('Title (A-Z)')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── 5. Sessions List Content ───
            if (filteredSessions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = filteredSessions[index];
                      final isBookmarked = _bookmarkedTitles.contains(session.title);

                      return RecommendedSessionCard(
                        session: session,
                        isBookmarked: isBookmarked,
                        onTap: () => _showSessionDetails(context, session),
                        onAddToSchedule: () {
                          setState(() {
                            if (_bookmarkedTitles.contains(session.title)) {
                              _bookmarkedTitles.remove(session.title);
                            } else {
                              _bookmarkedTitles.add(session.title);
                            }
                          });
                        },
                      );
                    },
                    childCount: filteredSessions.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  /// Top Header Banner matching the reference screenshot
  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9F5),
      ),
      child: Stack(
        children: [
          // Background graphic glow / illustration
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

          // Gradient wash for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF9F5),
                    const Color(0xFFFFF9F5).withValues(alpha: 0.92),
                    const Color(0xFFFFF9F5).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.75, 1.0],
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
                // Circular White Back Button
                GestureDetector(
                  onTap: () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      widget.onNavigateTab?.call(0);
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

                const SizedBox(height: 14),

                // Subtitle / Tag
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

                // Main Title: TEC-VERSE 2026
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'TEC-VERSE ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.3,
                        ),
                      ),
                      TextSpan(
                        text: '2026',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF97316),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 2),

                // Technology Sessions
                const Text(
                  'TECHNOLOGY SESSIONS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.4,
                  ),
                ),

                const SizedBox(height: 4),

                // Description
                const SizedBox(
                  width: 260,
                  child: Text(
                    'Research tracks, plenary talks, technical sessions and industry interactions',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Day Filter Button (All Days / Day 1 / Day 2)
  Widget _buildDayChip(String dayKey, String label) {
    final isSelected = _selectedDay == dayKey;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDay = dayKey),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF97316) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFF97316) : const Color(0xFFE5E7EB),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Technology Domains Section with Horizontal Scrollable Cards
  Widget _buildTechnologyDomainsFilterBar(List<String> userInterests) {
    final domainList = _liveDomains.isNotEmpty
        ? ['All', ..._liveDomains.map((d) => d.title)]
        : _availableDomains;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFFF97316)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'TECHNOLOGY DOMAINS',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Color(0xFFF97316),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  final auth = context.read<AuthController>();
                  if (auth.currentUser != null) {
                    _openInterestSelector(context, auth.currentUser!);
                  }
                },
                child: Text(
                  '${domainList.length - 1} Tracks >',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF97316),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: domainList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final domain = domainList[index];
              final isSelected = _selectedDomain == domain;
              final icon = DomainStyleHelper.getDomainIcon(domain);
              final isGreen = domain.toLowerCase().contains('green') || domain.toLowerCase().contains('power');

              return InkWell(
                onTap: () => setState(() => _selectedDomain = domain),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF97316) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFF97316) : const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFF97316).withValues(alpha: 0.28)
                            : const Color(0xFF102A43).withValues(alpha: 0.03),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : (isGreen ? const Color(0xFF059669) : const Color(0xFFF97316)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        domain,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching sessions found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your search query or selecting a different technology domain.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDomain = 'All';
                  _selectedDay = 'All';
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, SessionItem session) {
    final domainBg = DomainStyleHelper.getBadgeBgColor(session.domain);
    final domainText = DomainStyleHelper.getBadgeTextColor(session.domain);
    final isPlenary = session.sessionType.toUpperCase() == 'PLENARY' || session.isHighlight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: domainBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    session.domain.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: domainText,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPlenary ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (isPlenary ? 'PLENARY' : session.sessionType).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isPlenary ? const Color(0xFFB45309) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                if (session.isHighlight) ...[
                  const SizedBox(width: 6),
                  Row(
                    children: const [
                      Icon(Icons.star_rounded, size: 14, color: Color(0xFFEA580C)),
                      SizedBox(width: 2),
                      Text(
                        'Featured',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFF97316)),
                const SizedBox(width: 6),
                Text(
                  '${session.day} • ${session.time} (${session.duration})',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
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
                  session.hall,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (session.speaker.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFFF97316)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session.speaker,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (session.description != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 10),
              const Text(
                'Abstract & Overview',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                session.description!,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  height: 1.45,
                  fontSize: 12.5,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
