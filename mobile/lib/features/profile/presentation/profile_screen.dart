import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animation_utils.dart';
import '../../authentication/domain/authenticated_user.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../digital_pass/presentation/digital_pass_controller.dart';
import '../../digital_pass/presentation/digital_pass_screen.dart';
import '../../home/presentation/interest_selection_dialog.dart';
import '../../schedule/presentation/schedule_screen.dart';
import 'privacy_policy_screen.dart';
import 'widgets/delete_account_dialog.dart';

/// Redesigned Profile Screen matching the exact Tec-Verse 2026 Mobile UI.
///
/// Features:
/// - Top Bar: Back button, bold "PROFILE" title, and orange Settings button
/// - Profile Header Card: Integrated futuristic Tec-Verse 2026 banner graphic (profile.jpeg),
///   attendee avatar circle with initials, attendee name, designation, and organisation
/// - 2 Quick Shortcuts: "Event Pass" (QR icon) and "Schedule" (Clock icon)
/// - "WEBSITE REGISTRATION RECORD" section with 12-Digit Reference No., Email, Mobile, Category, Schedule
/// - "REGISTERED TECHNOLOGY DOMAINS" 2-column grid with "Edit Domains >" interactive selector
/// - Full-width "SIGN OUT OF Tec-Verse" primary orange action button
class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const ProfileScreen({super.key, this.onBackPressed});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.primaryOrange, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: AppTypography.headlineMedium.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of Tec-Verse? Your session and offline digital pass credentials will be safely logged out.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.signoutOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      final auth = context.read<AuthController>();
      final passCtrl = context.read<DigitalPassController>();

      passCtrl.clearPass();
      await auth.logout();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final passCtrl = context.read<DigitalPassController>();

    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );

    if (deleted == true) {
      passCtrl.clearPass();
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your account has been permanently deleted.'),
          backgroundColor: AppColors.emeraldSuccess,
        ),
      );
    }
  }

  void _openInterestSelector(BuildContext context) {
    final auth = context.read<AuthController>();
    final currentInterests = auth.currentUser?.interests ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InterestSelectionSheet(
        initialSelected: currentInterests,
        onSave: (newInterests) {
          auth.updateInterests(newInterests);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Technology domains updated successfully.'),
              backgroundColor: AppColors.surfaceElevated,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  /// Server stores DAY_1 / DAY_2 / BOTH; same wording as the confirmation PDF.
  static String _attendanceDaysLabel(String days) {
    final value = days.toUpperCase();
    final day1 = value.contains('DAY_1');
    final day2 = value.contains('DAY_2');
    if (day1 && !day2) return '26 November 2026';
    if (day2 && !day1) return '27 November 2026';
    return '26 & 27 November 2026';
  }

  void _copyReferenceNumber(BuildContext context, String ref) {
    Clipboard.setData(ClipboardData(text: ref));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reference No. $ref copied to clipboard'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, UserProfile user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Text(
                'Account & Preferences',
                style: AppTypography.headlineMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primaryOrange, size: 20),
                ),
                title: const Text('Edit Registered Technology Domains', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openInterestSelector(context);
                },
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                title: const Text('View Official Event Digital Pass', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DigitalPassScreen()));
                },
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary, size: 20),
                ),
                title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openPrivacyPolicy(context);
                },
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonError.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: AppColors.crimsonError, size: 20),
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.crimsonError),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteAccount(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'KK';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthController>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) {
            return const Center(child: Text('No attendee profile loaded.'));
          }

          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // 1. TOP HEADER BAR
                SliverToBoxAdapter(
                  child: _buildTopHeader(context, user),
                ),

                // 2. MAIN SCROLLABLE CONTENT BODY
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    80 + MediaQuery.of(context).padding.bottom,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 580),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Profile Header Card with Banner Graphic
                            FadeSlideTransition(
                              delay: Duration.zero,
                              child: _buildProfileHeaderCard(user),
                            ),

                            const SizedBox(height: 14),

                            // 2. Quick Action Shortcut Cards (Event Pass & Schedule)
                            FadeSlideTransition(
                              delay: const Duration(milliseconds: 50),
                              child: _buildQuickActionShortcuts(context),
                            ),

                            const SizedBox(height: 16),

                            // 3. Website Registration Record Card
                            FadeSlideTransition(
                              delay: const Duration(milliseconds: 100),
                              child: _buildWebsiteRegistrationCard(context, user),
                            ),

                            const SizedBox(height: 16),

                            // 4. Registered Technology Domains Card
                            FadeSlideTransition(
                              delay: const Duration(milliseconds: 150),
                              child: _buildTechnologyDomainsCard(context, user),
                            ),

                            const SizedBox(height: 22),

                            // 5. Primary Action: Sign Out Button
                            FadeSlideTransition(
                              delay: const Duration(milliseconds: 200),
                              child: _buildSignOutButton(context),
                            ),

                            const SizedBox(height: 8),

                            // 6. Privacy Policy & Account Deletion links
                            _buildLegalLinks(context),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 1. Top Header Bar
  Widget _buildTopHeader(BuildContext context, UserProfile user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Back Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF102A43), size: 17),
              tooltip: 'Back',
              onPressed: () {
                if (onBackPressed != null) {
                  onBackPressed!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),

          // Title: PROFILE
          Text(
            'PROFILE',
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF102A43),
            ),
          ),

          // Settings Button (Orange Gear)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded, color: AppColors.primaryOrange, size: 20),
              tooltip: 'Settings & Preferences',
              onPressed: () => _showSettingsSheet(context, user),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Profile Header Card with Banner Graphic (profile.jpeg)
  Widget _buildProfileHeaderCard(UserProfile user) {
    final initials = _getInitials(user.officialName);

    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Banner Image on right side
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 220,
              child: Image.asset(
                'assets/images/profile.jpeg',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),

            // Left-to-Right Soft Gradient Overlay for perfect text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.white.withValues(alpha: 0.88),
                      Colors.white.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.58, 0.72, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Right side Tec-Verse 2026 overlay text
            Positioned(
              right: 14,
              top: 12,
              bottom: 12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    textAlign: TextAlign.right,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tec-Verse\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 6),
                              Shadow(color: Colors.black45, blurRadius: 2),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: '2026',
                          style: TextStyle(
                            color: Color(0xFFFF9E66),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 6),
                              Shadow(color: Colors.black45, blurRadius: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'INNOVATE • LEARN • COLLABORATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Left side: Avatar + User details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Avatar with Orange Gradient
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFFF7043)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33FF6B1A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Name, Role, Organization
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.officialName.isNotEmpty ? user.officialName : 'Attendee',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.designation.isNotEmpty ? user.designation : 'Delegate',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryOrange,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          user.organization.isNotEmpty ? user.organization : 'Tec-Verse Attendee',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
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
          ],
        ),
      ),
    );
  }

  /// 3. Two Quick Shortcut Cards (Event Pass & Schedule)
  Widget _buildQuickActionShortcuts(BuildContext context) {
    return Row(
      children: [
        // Event Pass Shortcut
        Expanded(
          child: _buildActionTile(
            context: context,
            icon: Icons.qr_code_2_rounded,
            title: 'Event Pass',
            subtitle: 'View your digital pass',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DigitalPassScreen()),
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        // Schedule Shortcut
        Expanded(
          child: _buildActionTile(
            context: context,
            icon: Icons.access_time_filled_rounded,
            title: 'Schedule',
            subtitle: 'View event schedule',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ScaleOnPress(
      onTap: onTap,
      scaleFactor: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF102A43).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryOrange, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF102A43),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  /// 4. Website Registration Record Card
  Widget _buildWebsiteRegistrationCard(BuildContext context, UserProfile user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primaryOrange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'REGISTRATION DETAILS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Field 1: 12-Digit Reference No.
          _buildRecordRow(
            icon: Icons.tag_rounded,
            label: 'Reference No.',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.referenceNumber.isNotEmpty ? user.referenceNumber : '—',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 5),
                InkWell(
                  onTap: () => _copyReferenceNumber(
                    context,
                    user.referenceNumber.isNotEmpty ? user.referenceNumber : '—',
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Field 2: Email Address
          _buildRecordRow(
            icon: Icons.email_rounded,
            label: 'Email Address',
            valueWidget: Text(
              user.email.isNotEmpty ? user.email : '—',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102A43),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Field 3: Registered Mobile
          _buildRecordRow(
            icon: Icons.phone_rounded,
            label: 'Registered Mobile',
            valueWidget: Text(
              user.mobile.isNotEmpty ? user.mobile : '—',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102A43),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Field 4: Registration Category
          _buildRecordRow(
            icon: Icons.people_alt_rounded,
            label: 'Registration Category',
            valueWidget: Text(
              user.category.isNotEmpty ? user.category.toUpperCase() : '—',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102A43),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Field 5: Attendance Schedule
          _buildRecordRow(
            icon: Icons.calendar_month_rounded,
            label: 'Preferred Days',
            valueWidget: Text(
              _attendanceDaysLabel(user.attendanceDays),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102A43),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: AppColors.primaryOrange),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              child: valueWidget,
            ),
          ),
        ),
      ],
    );
  }

  /// 5. Registered Technology Domains Card
  Widget _buildTechnologyDomainsCard(BuildContext context, UserProfile user) {
    // Domains from database or fallback if none selected
    final domains = user.interests.isNotEmpty
        ? user.interests
        : [
            'IoT & Smart Systems',
            'Green Tech & Power Electronics',
            '5G/6G & Future Networks',
            'Semiconductors & VLSI',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with "Edit Domains >" action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryOrange,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PREFERRED DOMAINS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryOrange,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openInterestSelector(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Edit Domains',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.primaryOrange),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2-Column Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: domains.map((domain) {
                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getDomainIcon(domain),
                            size: 18,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              domain,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF102A43),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getDomainIcon(String domain) {
    final lower = domain.toLowerCase();
    if (lower.contains('iot') || lower.contains('smart')) {
      return Icons.memory_rounded;
    } else if (lower.contains('green') || lower.contains('power') || lower.contains('energy')) {
      return Icons.eco_rounded;
    } else if (lower.contains('5g') || lower.contains('6g') || lower.contains('network') || lower.contains('telecom')) {
      return Icons.cell_tower_rounded;
    } else if (lower.contains('semiconductor') || lower.contains('vlsi')) {
      return Icons.developer_board_rounded;
    } else if (lower.contains('ai') || lower.contains('supercomputing')) {
      return Icons.psychology_rounded;
    } else if (lower.contains('quantum')) {
      return Icons.blur_on_rounded;
    } else if (lower.contains('cyber')) {
      return Icons.security_rounded;
    } else if (lower.contains('health') || lower.contains('medical')) {
      return Icons.health_and_safety_rounded;
    } else if (lower.contains('robotics')) {
      return Icons.precision_manufacturing_rounded;
    }
    return Icons.hub_rounded;
  }

  /// 6. Primary Sign Out Action Button
  Widget _buildSignOutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _confirmLogout(context),
      icon: const Icon(Icons.exit_to_app_rounded, size: 20),
      label: const Text(
        'SIGN OUT OF Tec-Verse',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.signoutOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
        shadowColor: AppColors.signoutOrange.withValues(alpha: 0.3),
      ),
    );
  }

  /// 7. Privacy Policy and Delete Account links
  Widget _buildLegalLinks(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => _openPrivacyPolicy(context),
          icon: const Icon(Icons.privacy_tip_outlined, size: 16, color: AppColors.textSecondary),
          label: Text(
            'Privacy Policy',
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        TextButton.icon(
          onPressed: () => _confirmDeleteAccount(context),
          icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.crimsonError),
          label: Text(
            'Delete Account',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.crimsonError,
            ),
          ),
        ),
      ],
    );
  }
}
