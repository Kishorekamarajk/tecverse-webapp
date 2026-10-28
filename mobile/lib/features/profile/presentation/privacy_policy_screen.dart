import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/external_links.dart';

/// In-App Privacy Policy screen providing transparent, offline-accessible
/// privacy disclosures for Tec-Verse 2026 (in.cdac.tecverse.tec_app)
/// in full compliance with Google Play User Data policies.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkNavy, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Privacy Policy',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.darkNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Open in Browser',
            icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primaryOrange, size: 20),
            onPressed: () => openExternalUrl(ApiConstants.privacyPolicyUrl),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderSubtle, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header Card
              _buildHeaderCard(),

              const SizedBox(height: 20),

              // Section 1: Introduction & Scope
              _buildSectionCard(
                icon: Icons.info_outline_rounded,
                title: '1. Introduction & Scope',
                content:
                    'Tec-Verse 2026 is organized by the Centre for Development of Advanced Computing (C-DAC), '
                    'an autonomous scientific society under the Ministry of Electronics and Information Technology (MeitY), Government of India.\n\n'
                    'This Privacy Policy applies to the official "Tec-Verse 2026" mobile application (Android package: in.cdac.tecverse.tec_app) '
                    'and the official website (https://tec-verse.cdac.in). It discloses our policies on the collection, use, protection, '
                    'and disclosure of personal data for event attendees, exhibitors, and delegates.',
              ),

              const SizedBox(height: 16),

              // Section 2: Data We Collect
              _buildSectionCard(
                icon: Icons.badge_outlined,
                title: '2. Information We Collect',
                content:
                    'We collect only the information necessary to provide ticketing, accreditation, and seamless event participation:\n\n'
                    '• Registration Details: Full name, official email address, mobile phone number, login password (stored strictly as a one-way cryptographic hash), '
                    'registration category (e.g. Delegate, Student, Exhibitor), organization or institution name, designation, city, student ID (for student delegates), '
                    'and preferred attendance days.\n\n'
                    '• Passport Details (Foreign Nationals only): Passport number, expiration date, and full name as printed on passport, collected strictly for required '
                    'event security clearances and venue entry accreditation.\n\n'
                    '• App Usage & Preferences: Technology domain interests you choose, session bookmarks, questions submitted to the event FAQ/assistant, '
                    'and digital pass check-in status at the venue.\n\n'
                    '• What We DO NOT Collect: We do not access or collect your GPS location, phone contacts, photos, media gallery, or advertising identifiers. '
                    'We do not use your personal information for advertising or commercial profiling.',
              ),

              const SizedBox(height: 16),

              // Section 3: Microphone & Audio Usage
              _buildSectionCard(
                icon: Icons.mic_none_rounded,
                title: '3. Microphone Usage (Optional Voice Search)',
                content:
                    'The app requests microphone access (android.permission.RECORD_AUDIO) solely when you voluntarily tap the voice search / AI assistant button.\n\n'
                    '• Speech-to-Text: Audio is processed transiently by your device\'s built-in speech-recognition service to convert your voice into text queries.\n'
                    '• Privacy Guarantee: Tec-Verse does NOT record, transmit, or store any raw audio recordings on our servers. Audio processing is governed by your '
                    'device operating system\'s speech recognition service. You can use text search without ever granting microphone access.',
              ),

              const SizedBox(height: 16),

              // Section 4: How We Use Information
              _buildSectionCard(
                icon: Icons.security_rounded,
                title: '4. How We Use Collected Data',
                content:
                    'Your data is processed strictly for official event purposes:\n\n'
                    '• Digital Pass & Venue Entry: Generating your personalized digital pass and unique encrypted QR code for on-site security verification at Chennai Trade Centre.\n\n'
                    '• Authentication: One-time password (OTP) verification for secure login and account recovery.\n\n'
                    '• Event Communications: Delivering important schedule updates, keynote announcements, and venue alerts.\n\n'
                    '• Safety & Administration: Managing attendee counts, hall capacities, and overall venue safety.',
              ),

              const SizedBox(height: 16),

              // Section 5: Data Sharing & Third Parties
              _buildSectionCard(
                icon: Icons.share_outlined,
                title: '5. Sharing & Disclosure',
                content:
                    '• No Commercial Sale: We do not sell, rent, trade, or monetize personal information.\n\n'
                    '• Authorized Personnel: Data is accessible only to authorized C-DAC event administration and technical staff.\n\n'
                    '• Essential Infrastructure: Trusted service providers hosting our servers and delivering transactional OTP emails/SMS process data under strict confidentiality obligations.\n\n'
                    '• Maps Navigation: When you request directions to the venue, the app opens your preferred external map application (Google Maps / Apple Maps); no continuous location data is tracked.\n\n'
                    '• Legal Compliance: Data may only be disclosed if mandatory under Indian law or requested by government security agencies for venue safety.',
              ),

              const SizedBox(height: 16),

              // Section 6: Security & Retention
              _buildSectionCard(
                icon: Icons.lock_outline_rounded,
                title: '6. Data Security & Retention',
                content:
                    '• Encryption: All data transmitted between the mobile app and our servers uses industry-standard HTTPS/TLS encryption.\n\n'
                    '• Cryptographic Storage: Passwords are encrypted using salted one-way hashes. Authentication tokens are saved in Android Keystore / encrypted local storage.\n\n'
                    '• Retention: Personal registration data is retained only for the duration required for Tec-Verse 2026 event operations and post-event reporting, after which it is deleted or permanently anonymized.',
              ),

              const SizedBox(height: 16),

              // Section 7: Account Deletion (Google Play Requirement)
              _buildSectionCard(
                icon: Icons.person_remove_outlined,
                title: '7. Your Choices & Account Deletion',
                isHighlighted: true,
                content:
                    'You retain full control over your personal data. You can delete your account and all associated data at any time:\n\n'
                    '1. Inside the App: Open Profile → Delete Account and confirm deletion.\n'
                    '2. On the Website: Visit the public account deletion portal at:\n'
                    'https://tec-verse.cdac.in/account-deletion\n\n'
                    'Deleting your account permanently erases your attendee registration, digital entry pass, preference selections, and session bookmarks from our database.',
              ),

              const SizedBox(height: 16),

              // Section 8: Children's Privacy
              _buildSectionCard(
                icon: Icons.child_care_rounded,
                title: '8. Children\'s Privacy',
                content:
                    'Tec-Verse 2026 is an advanced technology convention intended for professionals, researchers, students, and attendees aged 13 and above. '
                    'We do not knowingly collect or solicit personal information from children under 13.',
              ),

              const SizedBox(height: 16),

              // Section 9: Developer Contact
              _buildSectionCard(
                icon: Icons.contact_mail_outlined,
                title: '9. Contact & Grievance',
                content:
                    'For questions, privacy inquiries, or data requests, please contact the organizing team:\n\n'
                    '• Developer: Centre for Development of Advanced Computing (C-DAC)\n'
                    '• Email: tec-verse@cdac.in\n'
                    '• Event Website: https://tec-verse.cdac.in\n'
                    '• Venue: Chennai Trade Centre, Nandambakkam, Chennai, Tamil Nadu, India',
              ),

              const SizedBox(height: 28),

              // Action buttons
              Center(
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => openExternalUrl(ApiConstants.privacyPolicyUrl),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primaryOrange),
                      label: Text(
                        'View on Website (tec-verse.cdac.in)',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.primaryOrange),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => openExternalUrl(ApiConstants.accountDeletionUrl),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textSecondary),
                      label: Text(
                        'Web Account Deletion Portal',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primaryOrange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tec-Verse 2026',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.darkNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'App Package: in.cdac.tecverse.tec_app',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightLavender,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.update_rounded, size: 14, color: AppColors.darkNavy),
                const SizedBox(width: 6),
                Text(
                  'Last Updated: October 28, 2026',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
    bool isHighlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.primaryOrange.withValues(alpha: 0.5) : AppColors.borderSubtle,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isHighlighted ? AppColors.primaryOrange : AppColors.darkNavy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
