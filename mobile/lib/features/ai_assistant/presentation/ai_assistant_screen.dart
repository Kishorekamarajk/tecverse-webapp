import 'package:flutter/material.dart';
import '../../../core/navigation/voice_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animation_utils.dart';
import '../../../core/widgets/futuristic_background.dart';
import '../../../core/widgets/gsap_loader.dart';
import '../../about/presentation/about_screen.dart';
import '../../digital_pass/presentation/digital_pass_screen.dart';
import '../../floor_plan/presentation/floor_plan_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../schedule/presentation/schedule_screen.dart';
import '../../sessions/presentation/sessions_screen.dart';
import '../data/tecverse_ai_service.dart';
import '../domain/ai_message.dart';
import '../domain/faq_item.dart';
import 'widgets/voice_assistant_modal.dart';

/// Professional, futuristic "Ask TEC-VERSE" AI Delegate Assistant & Copilot.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  List<FaqItem> _allFaqItems = [];
  String _selectedCategory = 'ALL';
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addInitialWelcomeMessage();
    _loadFaqItems();
  }

  Future<void> _loadFaqItems() async {
    final items = await TecverseAiService.getAllFaqItems();
    if (mounted) {
      setState(() {
        _allFaqItems = items;
      });
    }
  }

  void _addInitialWelcomeMessage() {
    _messages.add(
      AiMessage(
        id: 'welcome-msg',
        text: '👋 **Hello! I am your TEC-VERSE 2026 AI Delegate Copilot.**\n\n'
            'Ask me anything about:\n'
            '• Keynotes & session schedules\n'
            '• Turn-by-turn wayfinding to Halls 1–8 & stalls\n'
            '• Personalized recommendations based on your topics\n'
            '• Digital Pass, Wi-Fi & venue amenities\n\n'
            'Tap the **Microphone icon** below for hands-free voice assistance!',
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
        actions: const [
          AiActionLink(
            label: 'Explore Schedule',
            icon: Icons.calendar_today_rounded,
            actionType: AiActionType.openSchedule,
          ),
          AiActionLink(
            label: 'View Floor Plan',
            icon: Icons.map_outlined,
            actionType: AiActionType.openFloorPlan,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage([String? overrideText]) async {
    final text = overrideText ?? _textController.text.trim();
    if (text.isEmpty || _isTyping) return;

    if (overrideText == null) {
      _textController.clear();
    }

    final userMsg = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    final aiReply = await TecverseAiService.processQuery(text);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(aiReply);
      });
      _scrollToBottom();
    }
  }

  void _openVoiceAssistant() {
    VoiceAssistantModal.show(
      context,
      onVoiceQueryCompleted: (userQuery, aiReply) {
        setState(() {
          _messages.add(
            AiMessage(
              id: '${DateTime.now().millisecondsSinceEpoch}-user-voice',
              text: userQuery,
              sender: MessageSender.user,
              timestamp: DateTime.now(),
              isVoiceGenerated: true,
            ),
          );
          _messages.add(aiReply);
        });
        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleActionLink(AiActionLink action) {
    switch (action.actionType) {
      case AiActionType.openHome:
        VoiceNavigationService.navigateTo(VoiceNavDestination.home);
        break;
      case AiActionType.openFloorPlan:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FloorPlanScreen(initialHallId: action.targetId),
          ),
        );
        break;
      case AiActionType.openSchedule:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        );
        break;
      case AiActionType.openSessions:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SessionsScreen()),
        );
        break;
      case AiActionType.openPass:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DigitalPassScreen()),
        );
        break;
      case AiActionType.openAbout:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        );
        break;
      case AiActionType.openProfile:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
      case AiActionType.openLogin:
        VoiceNavigationService.navigateTo(VoiceNavDestination.login);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: TecVerseAmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Message Stream
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    final message = _messages[index];
                    return _buildMessageItem(message);
                  },
                ),
              ),

              // Dynamic Horizontal FAQ Questions Bar from Database
              _buildHorizontalFaqBar(),

              // Bottom Input & Voice Trigger Bar
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface.withValues(alpha: 0.95),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ASK TEC-VERSE',
                style: AppTypography.headlineMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.emeraldSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI COPILOT • ONLINE',
                    style: AppTypography.metaTag.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldSuccess,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Voice Assistant',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.mic_rounded, color: AppColors.primaryOrange, size: 18),
          ),
          onPressed: _openVoiceAssistant,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: AppColors.borderSubtle, height: 1.0),
      ),
    );
  }

  Widget _buildMessageItem(AiMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryOrange, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? null : AppColors.surface,
                gradient: isUser ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: isUser ? null : Border.all(color: AppColors.borderCard),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppColors.primaryOrange : const Color(0xFF102A43)).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isVoiceGenerated) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 13,
                          color: isUser ? Colors.white70 : AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'VOICE QUERY',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isUser ? Colors.white70 : AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  _buildFormattedText(message.text, isUser),
                  if (message.actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.actions.map((action) {
                        return ScaleOnPress(
                          onTap: () => _handleActionLink(action),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryOrange.withValues(alpha: 0.4),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(action.icon, size: 14, color: AppColors.primaryOrange),
                                const SizedBox(width: 6),
                                Text(
                                  action.label,
                                  style: AppTypography.metaTag.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primaryOrange),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*([^*]+)\*\*|\*([^*]+)\*|([^*]+))');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      if (match.group(2) != null) {
        // Bold **text**
        spans.add(
          TextSpan(
            text: match.group(2),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isUser ? Colors.white : AppColors.textPrimary,
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // Italic *text*
        spans.add(
          TextSpan(
            text: match.group(3),
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isUser ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // Normal text
        spans.add(
          TextSpan(
            text: match.group(4),
            style: TextStyle(
              fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
              color: isUser ? Colors.white : AppColors.textPrimary,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: AppTypography.bodySmall.copyWith(
          fontSize: 13,
          height: 1.45,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryOrange, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderCard),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GsapElasticWaveLoader(height: 12, barCount: 4, spacing: 3),
                const SizedBox(width: 8),
                Text(
                  'AI is thinking...',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFaqBar() {
    if (_allFaqItems.isEmpty) return const SizedBox.shrink();

    final filteredFaqs = _selectedCategory == 'ALL'
        ? _allFaqItems
        : _allFaqItems.where((f) => f.pageKey.toUpperCase() == _selectedCategory).toList();

    final distinctCategories = ['ALL', ..._allFaqItems.map((f) => f.pageKey.toUpperCase()).where((k) => k.isNotEmpty).toSet()];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: FAQ Label + Category Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.primaryOrange),
                const SizedBox(width: 5),
                Text(
                  'FAQ QUESTIONS',
                  style: AppTypography.metaTag.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_allFaqItems.length} in DB',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
                const Spacer(),
                // Dynamic Category Filter Pills
                ...distinctCategories.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: _buildCategoryPill(cat),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Horizontal Scroll View of FAQ Cards
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredFaqs.length,
              itemBuilder: (context, index) {
                final faq = filteredFaqs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ScaleOnPress(
                    onTap: () => _handleSendMessage(faq.question),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF102A43).withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  faq.pageKey.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryOrange,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_rounded, size: 11, color: AppColors.primaryOrange),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            faq.question,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Voice Assistant Microphone Launcher
          ScaleOnPress(
            onTap: _openVoiceAssistant,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.35)),
              ),
              child: const Center(
                child: Icon(Icons.mic_rounded, color: AppColors.primaryOrange, size: 22),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Text Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask anything about TEC-VERSE 2026...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send Button
          ScaleOnPress(
            onTap: () => _handleSendMessage(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
