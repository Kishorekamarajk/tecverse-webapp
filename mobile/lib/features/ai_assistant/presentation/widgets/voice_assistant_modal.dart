import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/navigation/voice_navigation_service.dart';
import '../../../../core/services/speech_voice_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gsap_loader.dart';
import '../../data/tecverse_ai_service.dart';
import '../../domain/ai_message.dart';

enum VoiceState { idle, listening, processing, speaking, navigating, error }

/// Interactive Voice Assistant Modal with real-time speech-to-text recognition,
/// automatic silence auto-trigger, text-to-speech speaker responses, and direct voice navigation.
class VoiceAssistantModal extends StatefulWidget {
  final Function(String userQuery, AiMessage aiResponse)? onVoiceQueryCompleted;

  const VoiceAssistantModal({
    super.key,
    this.onVoiceQueryCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    Function(String userQuery, AiMessage aiResponse)? onVoiceQueryCompleted,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Voice Assistant',
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, _, _) {
        return VoiceAssistantModal(onVoiceQueryCompleted: onVoiceQueryCompleted);
      },
    );
  }

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with TickerProviderStateMixin {
  late AnimationController _waveformController;
  late AnimationController _rippleController;
  final TextEditingController _voiceInputController = TextEditingController();

  VoiceState _state = VoiceState.listening;
  String _transcriptText = 'Listening... Speak now or tap below';
  String _aiResponseSnippet = '';
  double _soundLevel = 0.0;
  Timer? _silenceTimer;
  Timer? _navTimer;
  Timer? _fallbackTimer;

  List<String> _quickVoiceCommands = [];
  bool _showTextInput = false;

  @override
  void initState() {
    super.initState();

    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loadVoiceCommands();
    _startRealVoiceListening();
  }

  Future<void> _loadVoiceCommands() async {
    final prompts = await TecverseAiService.getSamplePrompts();
    if (mounted) {
      setState(() {
        _quickVoiceCommands = prompts;
      });
    }
  }

  /// Start recording voice from the microphone
  Future<void> _startRealVoiceListening() async {
    _silenceTimer?.cancel();
    setState(() {
      _state = VoiceState.listening;
      _transcriptText = 'Listening... Speak "Go to sessions" or tap a prompt';
    });

    final started = await SpeechVoiceService.instance.startListening(
      onResult: (words, isFinal) {
        if (!mounted) return;
        final trimmed = words.trim();
        if (trimmed.isNotEmpty) {
          setState(() {
            _transcriptText = trimmed;
            _voiceInputController.text = trimmed;
          });

          // Reset silence timer on each spoken fragment
          _silenceTimer?.cancel();

          if (isFinal) {
            _executeVoiceQuery(trimmed);
          } else {
            // Auto-execute after 900ms pause if user pauses speaking
            _silenceTimer = Timer(const Duration(milliseconds: 900), () {
              if (mounted && _state == VoiceState.listening && _transcriptText.trim().isNotEmpty) {
                _executeVoiceQuery(_transcriptText.trim());
              }
            });
          }
        }
      },
      onSoundLevelChange: (level) {
        if (mounted) {
          setState(() {
            _soundLevel = (level / 10).clamp(0.0, 1.0);
          });
        }
      },
      onError: () {
        if (mounted) {
          setState(() {
            _transcriptText = 'Tap the microphone or select a prompt below';
          });
        }
      },
    );

    if (!started && mounted) {
      setState(() {
        _transcriptText = 'Voice Assistant ready! Say "Go to Sessions" or tap a prompt.';
      });
    }
  }

  Future<void> _executeVoiceQuery(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _silenceTimer?.cancel();
    _fallbackTimer?.cancel();
    _navTimer?.cancel();
    await SpeechVoiceService.instance.stopListening();

    if (!mounted) return;

    setState(() {
      _transcriptText = cleanQuery;
      _voiceInputController.text = cleanQuery;
      _state = VoiceState.processing;
    });

    final aiResponse = await TecverseAiService.processQuery(cleanQuery, isVoice: true);

    if (!mounted) return;

    final navResult = VoiceNavigationService.evaluateNavigationIntent(cleanQuery);

    if (navResult.isNavigation && navResult.destination != null) {
      setState(() {
        _state = VoiceState.navigating;
        _aiResponseSnippet = navResult.feedbackMessage;
      });

      // Speak navigation feedback aloud via speaker
      unawaited(SpeechVoiceService.instance.speak(navResult.feedbackMessage));

      // Smooth transition to target screen
      _navTimer = Timer(const Duration(milliseconds: 1300), () {
        if (mounted) {
          Navigator.of(context).pop();
          if (widget.onVoiceQueryCompleted != null) {
            widget.onVoiceQueryCompleted!(cleanQuery, aiResponse);
          }
          VoiceNavigationService.navigateTo(navResult.destination!);
        }
      });
      return;
    }

    // Q&A response display
    final spokenText = aiResponse.text.replaceAll('*', '').replaceAll('•', '-');
    setState(() {
      _state = VoiceState.speaking;
      _aiResponseSnippet = spokenText;
      if (_aiResponseSnippet.length > 200) {
        _aiResponseSnippet = '${_aiResponseSnippet.substring(0, 200)}...';
      }
    });

    // Speak response aloud via speaker
    unawaited(SpeechVoiceService.instance.speak(
      spokenText,
      onComplete: () {
        if (mounted) {
          Timer(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.of(context).pop();
              if (widget.onVoiceQueryCompleted != null) {
                widget.onVoiceQueryCompleted!(cleanQuery, aiResponse);
              }
            }
          });
        }
      },
    ));

    // Fallback auto-close after 4.5s
    _fallbackTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted && _state == VoiceState.speaking) {
        Navigator.of(context).pop();
        if (widget.onVoiceQueryCompleted != null) {
          widget.onVoiceQueryCompleted!(cleanQuery, aiResponse);
        }
      }
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _fallbackTimer?.cancel();
    _navTimer?.cancel();
    SpeechVoiceService.instance.stopListening();
    SpeechVoiceService.instance.stopSpeaking();
    _voiceInputController.dispose();
    _waveformController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: math.min(MediaQuery.of(context).size.width - 32, 430),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.4),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 6,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF102A43).withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Title & Control Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.smart_toy_rounded, color: Colors.white, size: 15),
                            SizedBox(width: 6),
                            Text(
                              'VOICE ASSISTANT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showTextInput = !_showTextInput;
                              });
                            },
                            icon: Icon(
                              _showTextInput ? Icons.mic_rounded : Icons.keyboard_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            tooltip: _showTextInput ? 'Switch to Voice' : 'Type Command',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Central Glowing Mic / Robot Orb with live audio reactivity
                  _buildAcousticWaveOrb(),

                  const SizedBox(height: 20),

                  // Live Status Heading
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _getStatusHeading(),
                      key: ValueKey<VoiceState>(_state),
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Real-time Transcript / Feedback Bubble
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _state == VoiceState.navigating
                            ? AppColors.cyanAccent.withValues(alpha: 0.4)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _state == VoiceState.speaking || _state == VoiceState.navigating
                              ? _aiResponseSnippet
                              : _transcriptText,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12.5,
                            fontWeight: (_state == VoiceState.speaking || _state == VoiceState.navigating)
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: _state == VoiceState.navigating
                                ? AppColors.cyanAccent
                                : (_state == VoiceState.speaking
                                    ? AppColors.primaryOrange
                                    : AppColors.textSecondary),
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_state == VoiceState.speaking) ...[
                          const SizedBox(height: 8),
                          const GsapElasticWaveLoader(
                            height: 12,
                            barCount: 5,
                            spacing: 3.5,
                            color: AppColors.primaryOrange,
                          ),
                        ],
                        if (_state == VoiceState.navigating) ...[
                          const SizedBox(height: 8),
                          const GsapElasticWaveLoader(
                            height: 12,
                            barCount: 5,
                            spacing: 3.5,
                            color: AppColors.cyanAccent,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Visible Text Input Box
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voiceInputController,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. "Go to sessions" or "Where is hall 3?"',
                            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.borderSubtle),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.borderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primaryOrange),
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _executeVoiceQuery(val.trim());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final val = _voiceInputController.text.trim();
                          if (val.isNotEmpty) {
                            _executeVoiceQuery(val);
                          } else {
                            _startRealVoiceListening();
                          }
                        },
                        icon: Icon(
                          _voiceInputController.text.trim().isNotEmpty ? Icons.send_rounded : Icons.mic_rounded,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick Voice Prompts & Navigation chips
                  if (_state == VoiceState.listening || _state == VoiceState.idle) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'OR TAP A QUICK VOICE COMMAND:',
                        style: AppTypography.metaTag.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _quickVoiceCommands.map((cmd) {
                          final isNav = cmd.toLowerCase().startsWith('go to');
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(
                                cmd,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isNav ? AppColors.cyanAccent : AppColors.textPrimary,
                                ),
                              ),
                              avatar: Icon(
                                isNav ? Icons.near_me_rounded : Icons.mic_none_rounded,
                                size: 14,
                                color: isNav ? AppColors.cyanAccent : AppColors.primaryOrange,
                              ),
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                color: isNav
                                    ? AppColors.cyanAccent.withValues(alpha: 0.4)
                                    : AppColors.primaryOrange.withValues(alpha: 0.35),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onPressed: () {
                                _voiceInputController.text = cmd;
                                _executeVoiceQuery(cmd);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusHeading() {
    switch (_state) {
      case VoiceState.listening:
        return 'Listening for Voice Query...';
      case VoiceState.processing:
        return 'Analyzing Intent with Neural AI...';
      case VoiceState.navigating:
        return 'Executing Navigation...';
      case VoiceState.speaking:
        return 'Speaking Response...';
      case VoiceState.idle:
      case VoiceState.error:
        return 'Voice Assistant Ready';
    }
  }

  Widget _buildAcousticWaveOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveformController, _rippleController]),
      builder: (context, _) {
        final waveVal = _waveformController.value;
        final rippleVal = _rippleController.value;
        final dynamicBoost = _soundLevel * 18;

        return GestureDetector(
          onTap: () {
            if (_voiceInputController.text.trim().isNotEmpty) {
              _executeVoiceQuery(_voiceInputController.text.trim());
            } else {
              _startRealVoiceListening();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulsing Ripple Rings
              if (_state == VoiceState.listening ||
                  _state == VoiceState.speaking ||
                  _state == VoiceState.navigating) ...[
                Container(
                  width: 140 + (rippleVal * 40) + dynamicBoost,
                  height: 140 + (rippleVal * 40) + dynamicBoost,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (_state == VoiceState.navigating ? AppColors.cyanAccent : AppColors.primaryOrange)
                          .withValues(alpha: 0.25 * (1.0 - rippleVal)),
                      width: 1.8,
                    ),
                  ),
                ),
                Container(
                  width: 115 + (rippleVal * 24) + dynamicBoost,
                  height: 115 + (rippleVal * 24) + dynamicBoost,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (_state == VoiceState.navigating ? AppColors.cyanAccent : AppColors.primaryOrange)
                          .withValues(alpha: 0.40 * (1.0 - rippleVal)),
                      width: 1.5,
                    ),
                  ),
                ),
              ],

              // Central Glowing Mic / Robot Orb
              Container(
                width: 88 + dynamicBoost * 0.5,
                height: 88 + dynamicBoost * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _state == VoiceState.navigating
                      ? const LinearGradient(
                          colors: [AppColors.cyanAccent, Color(0xFF0077B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [AppColors.primaryOrange, Color(0xFFFF9E66)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: (_state == VoiceState.navigating ? AppColors.cyanAccent : AppColors.primaryOrange)
                          .withValues(alpha: 0.45 + (math.sin(waveVal * math.pi) * 0.25)),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _state == VoiceState.navigating
                        ? Icons.explore_rounded
                        : (_state == VoiceState.speaking
                            ? Icons.volume_up_rounded
                            : (_state == VoiceState.processing
                                ? Icons.auto_awesome_rounded
                                : Icons.mic_rounded)),
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
