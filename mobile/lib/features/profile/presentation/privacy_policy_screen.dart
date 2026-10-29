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
                    'Registration Details: Full name, email address, mobile phone number and password (stored as a one-way hash), '
                    'registration category (e.g. Delegate, Student, Exhibitor), organization or institution name, designation, city, student ID (for student delegates), '
                    'and preferred attendance days.\n\n'
                    'Passport Details (Foreign Nationals only): Passport number, expiration date, and full name as printed on passport, collected where required for '
                    'event entry, identity verification or security procedures.\n\n'
                    'App Usage & Preferences: Technology domain interests you choose and text questions submitted to the event FAQ/assistant, including recognized text from voice search; '
                    'and digital pass check-in status at the venue.\n\n'
                    'Data not collected through app permissions: the app does not request GPS, contacts, camera, photos or media permissions, and does not use advertising identifiers. '
                    'We do not use your personal information for advertising or commercial profiling.',
              ),

              const SizedBox(height: 16),

              // Section 3: Microphone & Audio Usage
              _buildSectionCard(
                icon: Icons.mic_none_rounded,
                title: '3. Microphone Usage (Optional Voice Search)',
                content:
                    'Before Android asks for microphone access, the app explains voice search and lets you choose whether to continue. Permission is requested only after you tap the microphone; you can deny it and type instead.\n\n'
                    'Your device\'s speech-recognition service processes speech and returns recognized text. Tec-Verse sends that text to its FAQ service to answer your question and does not upload or store raw audio on Tec-Verse servers. Your device or speech provider may process audio under its own privacy policy. You can revoke microphone access in Android Settings.',
              ),

              const SizedBox(height: 16),

              // Section 4: How We Use Information
              _buildSectionCard(
                icon: Icons.security_rounded,
                title: '4. How We Use Collected Data',
                content:
                    'Your data is processed strictly for official event purposes:\n\n'
                    'Digital Pass & Venue Entry: Generating your personalized digital pass and QR code for registration verification and event entry.\n\n'
                    'Authentication: One-time password (OTP) verification for secure login and account recovery.\n\n'
                    'Event Communications: Delivering registration confirmations, schedule information and operational event notices.\n\n'
                    'Safety & Administration: Managing registration, entry and event operations.',
              ),

              const SizedBox(height: 16),

              // Section 5: Data Sharing & Third Parties
              _buildSectionCard(
                icon: Icons.share_outlined,
                title: '5. Sharing & Disclosure',
                content:
                    'We do not sell personal data. Authorized C-DAC event personnel may access data for their work. Hosting, database, email and SMS providers process data as needed to operate services and deliver messages. Google Fonts may receive a font request and standard connection information. Your device speech-recognition provider may process audio when you choose voice search. Maps providers receive directions information when you choose to open directions. We may disclose relevant data when required by applicable law or legal process.',
              ),

              const SizedBox(height: 16),

              // Section 6: Security & Retention
              _buildSectionCard(
                icon: Icons.lock_outline_rounded,
                title: '6. Data Security & Retention',
                content:
                    'We use HTTPS for supported app-to-server connections, store passwords as one-way BCrypt hashes, and store app session information using Android secure storage. Access to administrative systems is restricted to authorized personnel. These safeguards reduce risk but cannot guarantee that data will never be accessed through a compromised account, device, system or service provider. Protect your password and device.\n\n'
                    'Registration information is retained while needed for event administration, reporting, dispute handling and legal obligations. Temporary verification codes expire. Session tokens are removed at sign-out, expiry or account deletion.',
              ),

              const SizedBox(height: 16),

              // Section 7: Account Deletion (Google Play Requirement)
              _buildSectionCard(
                icon: Icons.person_remove_outlined,
                title: '7. Your Choices & Account Deletion',
                isHighlighted: true,
                content:
                    'You can request account deletion at any time:\n\n'
                    '1. Inside the App: Open Profile > Delete Account and confirm using your current password.\n'
                    '2. On the Website: Visit the public account deletion portal at:\n'
                    'https://tec-verse.cdac.in/account-deletion\n\n'
                    'In-app deletion asks you to confirm using your current password, then removes your attendee registration, digital pass, app preferences, notifications and check-in records from active service records and ends account access. Information may remain for a limited period where required by law or necessary for a specific security, audit or event-administration obligation. Uninstalling the app only removes app data from your device; it does not delete your server-side account. Use the Delete Account option in Profile or the website deletion page.',
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
                  'Last Updated: October 29, 2026',
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
