import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/tech_button.dart';

/// Interactive technology interest selection modal sheet.
class InterestSelectionSheet extends StatefulWidget {
  final List<String> initialSelected;
  final void Function(List<String>) onSave;

  const InterestSelectionSheet({
    super.key,
    required this.initialSelected,
    required this.onSave,
  });

  static const List<String> availableDomains = [
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

  @override
  State<InterestSelectionSheet> createState() => _InterestSelectionSheetState();
}

class _InterestSelectionSheetState extends State<InterestSelectionSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
    if (_selected.isEmpty) {
      _selected = {'AI & Supercomputing', 'Cybersecurity'};
    }
  }

  void _toggle(String domain) {
    setState(() {
      if (_selected.contains(domain)) {
        if (_selected.length > 1) {
          _selected.remove(domain);
        }
      } else {
        _selected.add(domain);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Personalize Your TEC-VERSE Experience',
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Select technology areas to tailor your session recommendations and exhibition guides.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: InterestSelectionSheet.availableDomains.map((domain) {
              final isChosen = _selected.contains(domain);
              return InkWell(
                onTap: () => _toggle(domain),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isChosen
                        ? AppColors.cyanAccent.withValues(alpha: 0.18)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChosen ? AppColors.cyanAccent : AppColors.borderSubtle,
                      width: isChosen ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isChosen ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                        size: 16,
                        color: isChosen ? AppColors.cyanAccent : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        domain,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: isChosen ? FontWeight.w600 : FontWeight.w400,
                          color: isChosen ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
          TechButton(
            text: 'APPLY PREFERENCES',
            onPressed: () {
              widget.onSave(_selected.toList());
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
