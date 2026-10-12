import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The official TEC-VERSE 2026 event start and end datetime in IST (UTC+5:30).
/// November 26, 2026 at 09:00 AM IST to November 27, 2026 at 06:00 PM IST.
const _kEventStart = '2026-11-26T09:00:00+05:30';
const _kEventEnd = '2026-11-27T18:00:00+05:30';

enum EventStatus { upcoming, live, concluded }

/// Reusable dynamic countdown and live status widget for TEC-VERSE 2026.
///
/// Ticks every second:
/// - When before event start: Shows active countdown ([X DAYS TO GO] + [DAYS • HRS • MIN • SEC])
/// - When event starts / is ongoing: Displays animated [LIVE NOW] badge + live event message
/// - When event has concluded: Displays [EVENT CONCLUDED] status
class EventCountdownWidget extends StatefulWidget {
  /// Whether to show only the compact pill.
  final bool compact;

  const EventCountdownWidget({super.key, this.compact = true});

  @override
  State<EventCountdownWidget> createState() => _EventCountdownWidgetState();
}

class _EventCountdownWidgetState extends State<EventCountdownWidget> {
  late final DateTime _eventStart;
  late final DateTime _eventEnd;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  EventStatus _status = EventStatus.upcoming;

  @override
  void initState() {
    super.initState();
    _eventStart = DateTime.parse(_kEventStart);
    _eventEnd = DateTime.parse(_kEventEnd);
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final now = DateTime.now();
    if (now.isBefore(_eventStart)) {
      final diff = _eventStart.difference(now);
      if (mounted) {
        setState(() {
          _status = EventStatus.upcoming;
          _remaining = diff.isNegative ? Duration.zero : diff;
        });
      }
    } else if (now.isBefore(_eventEnd)) {
      if (mounted) {
        setState(() {
          _status = EventStatus.live;
          _remaining = Duration.zero;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _status = EventStatus.concluded;
          _remaining = Duration.zero;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _days => _remaining.inDays;
  int get _hours => _remaining.inHours % 24;
  int get _minutes => _remaining.inMinutes % 60;
  int get _seconds => _remaining.inSeconds % 60;

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case EventStatus.live:
        return _buildEventLiveRow();
      case EventStatus.concluded:
        return _buildEventConcludedRow();
      case EventStatus.upcoming:
        return _buildCountdownRow();
    }
  }

  /// Active countdown row: [X DAYS TO GO] + subtext row
  Widget _buildCountdownRow() {
    return Row(
      children: [
        // Days-to-go pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulseDot(color: AppColors.primaryOrange),
              const SizedBox(width: 6),
              Text(
                '$_days DAYS TO GO',
                style: AppTypography.metaTag.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Hours • Minutes • Seconds subtext
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.3,
              ),
              children: [
                TextSpan(
                  text: '$_days',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' DAYS • '),
                TextSpan(
                  text: _twoDigit(_hours),
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' HRS • '),
                TextSpan(
                  text: _twoDigit(_minutes),
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' MIN • '),
                TextSpan(
                  text: _twoDigit(_seconds),
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' SEC'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Live Now row when the countdown ends and event is active
  Widget _buildEventLiveRow() {
    return Row(
      children: [
        // Pulsing "LIVE NOW" Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: AppColors.crimsonError.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.crimsonError.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulseDot(color: AppColors.crimsonError),
              const SizedBox(width: 6),
              Text(
                'LIVE NOW',
                style: AppTypography.metaTag.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.crimsonError,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Descriptive Live subtext
        Expanded(
          child: Text(
            'EVENT IN PROGRESS • HAPPENING TODAY',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Event Concluded row after event end date
  Widget _buildEventConcludedRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'EVENT CONCLUDED',
            style: AppTypography.metaTag.copyWith(
              fontSize: 9.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');
}

/// Pulsing dot that animates independently via its own controller.
class _PulseDot extends StatefulWidget {
  final Color? color;

  const _PulseDot({this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? AppColors.primaryOrange;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dotColor.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
              color: dotColor.withValues(alpha: _anim.value * 0.6),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
