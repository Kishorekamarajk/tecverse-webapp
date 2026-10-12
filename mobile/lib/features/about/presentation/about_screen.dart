import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/animation_utils.dart';

/// Pixel-perfect About Screen matching the TEC-VERSE design:
/// 1. "ORGANISED BY" Card with top logo containers & bottom detail cards (C-DAC, SAMEER, C-MET)
/// 2. "ABOUT" Card with Overview text & building illustration with deep-tech network nodes
class AboutScreen extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final Function(int tabIndex)? onNavigateTab;

  const AboutScreen({
    super.key,
    this.onBackPressed,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 840;
            final horizontalPadding = isDesktop ? 40.0 : 16.0;
            final maxContentWidth = isDesktop ? 780.0 : double.infinity;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top App Bar
                SliverToBoxAdapter(
                  child: _buildTopHeader(context),
                ),

                // Main Content Body
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    96 + MediaQuery.of(context).padding.bottom,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. ABOUT Card
                            FadeSlideTransition(
                              delay: Duration.zero,
                              child: _buildAboutCard(context),
                            ),

                            const SizedBox(height: 18),

                            // 2. ORGANISED BY Card
                            FadeSlideTransition(
                              delay: const Duration(milliseconds: 100),
                              child: _buildOrganisedByCard(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Top Header Bar
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1E6DF), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          if (onBackPressed != null) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E293B),
                  size: 18,
                ),
                onPressed: onBackPressed,
                tooltip: 'Back',
              ),
            ),
            const SizedBox(width: 12),
          ],
          Image.asset(
            'assets/images/tecverselogo.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.blur_on_rounded,
              size: 32,
              color: Color(0xFFEA580C),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'About TEC-VERSE',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1),
                Text(
                  'Exhibition & Conclave • MeitY R&D Consortium',
                  style: TextStyle(
                    fontSize: 11,
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
    );
  }

  // ===========================================================================
  // 1. ORGANISED BY CARD
  // ===========================================================================
  Widget _buildOrganisedByCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1E8E2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Category Badge + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orange Building / Institution Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE0D0)),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFFEA580C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORGANISED BY',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFEA580C),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 32,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Header Text: Consortium of Scientific Societies (CSC) • MeitY
          const Text(
            'Consortium of Scientific Societies\n(CSC) • MeitY',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 18),

          // Top Row: 3 Logo Display Cards (1.svg = C-DAC, 2.svg = SAMEER, 3.svg = C-MET)
          Row(
            children: [
              Expanded(
                child: _buildSvgLogoBox(
                  assetPath: 'assets/images/1.svg',
                  bgColor: const Color(0xFFF0F9FF),
                  borderColor: const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSvgLogoBox(
                  assetPath: 'assets/images/2.svg',
                  bgColor: const Color(0xFFFFF7F2),
                  borderColor: const Color(0xFFFFE0D0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSvgLogoBox(
                  assetPath: 'assets/images/3.svg',
                  bgColor: const Color(0xFFF5F3FF),
                  borderColor: const Color(0xFFEDE9FE),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom Row: 3 Detail Institution Cards (C-DAC, SAMEER, C-MET)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. C-DAC Card
                Expanded(
                  child: _buildInstitutionCard(
                    context: context,
                    name: 'C-DAC',
                    fullName: 'Centre for\nDevelopment of\nAdvanced\nComputing',
                    titleColor: const Color(0xFF0284C7),
                    arrowColor: const Color(0xFF0284C7),
                    bgGradient: const LinearGradient(
                      colors: [Color(0xFFEFF8FF), Color(0xFFE0F2FE)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderColor: const Color(0xFFBAE6FD),
                    onTap: () => _showOrgDetailsModal(
                      context,
                      name: 'C-DAC',
                      title: 'Centre for Development of Advanced Computing',
                      mandate:
                          'India’s premier R&D organization under MeitY for Supercomputing (PARAM series), Artificial Intelligence, Quantum Computing, Cyber Security, and Multilingual Computing.',
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // 2. SAMEER Card
                Expanded(
                  child: _buildInstitutionCard(
                    context: context,
                    name: 'SAMEER',
                    fullName: 'Society for\nApplied\nMicrowave\nElectronics\nEngineering\n& Research',
                    titleColor: const Color(0xFFEA580C),
                    arrowColor: const Color(0xFFEA580C),
                    bgGradient: const LinearGradient(
                      colors: [Color(0xFFFFF7F2), Color(0xFFFFEDD5)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderColor: const Color(0xFFFFD4BE),
                    onTap: () => _showOrgDetailsModal(
                      context,
                      name: 'SAMEER',
                      title: 'Society for Applied Microwave Electronics Engineering & Research',
                      mandate:
                          'Pioneering institution specializing in RF & Microwave Systems, Radar Technologies, Atmospheric Radar, EMI/EMC Testing, and Medical Linear Accelerators (LINAC).',
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // 3. C-MET Card
                Expanded(
                  child: _buildInstitutionCard(
                    context: context,
                    name: 'C-MET',
                    fullName: 'Centre for\nMaterials for\nElectronics\nTechnology',
                    titleColor: const Color(0xFF9333EA),
                    arrowColor: const Color(0xFF9333EA),
                    bgGradient: const LinearGradient(
                      colors: [Color(0xFFFAF5FF), Color(0xFFEDE9FE)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderColor: const Color(0xFFDDD6FE),
                    onTap: () => _showOrgDetailsModal(
                      context,
                      name: 'C-MET',
                      title: 'Centre for Materials for Electronics Technology',
                      mandate:
                          'Dedicated to the development of indigenous electronic materials, semiconductor substrates, aerogels, piezoelectrics, and Li-ion battery recycling technologies.',
                      color: const Color(0xFF9333EA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single Top Row SVG Logo Box using 1.svg, 2.svg, 3.svg
  Widget _buildSvgLogoBox({
    required String assetPath,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Icon(
            Icons.business_rounded,
            color: Color(0xFF64748B),
            size: 28,
          ),
        ),
      ),
    );
  }

  /// Single Detailed Institution Card (C-DAC, SAMEER, C-MET)
  Widget _buildInstitutionCard({
    required BuildContext context,
    required String name,
    required String fullName,
    required Color titleColor,
    required Color arrowColor,
    required LinearGradient bgGradient,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: titleColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name: C-DAC / SAMEER / C-MET
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Full Name / Role
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                    height: 1.25,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),
                const SizedBox(height: 10),

                // Arrow Action Circle Button
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: arrowColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: arrowColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. ABOUT CARD (With Building Asset & Deep-Tech Network Overlay)
  // ===========================================================================
  Widget _buildAboutCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Green Info Icon + ABOUT Badge + Underline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ABOUT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 32,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Title: TEC-VERSE Overview
          const Text(
            'TEC-VERSE Overview',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 14),

          // Content Row: Left Text + Right Building Image with tech nodes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Narrative Paragraph
              Expanded(
                flex: 11,
                child: Text(
                  'Tec-verse is a technology exhibition and conclave shaped by MeitY\'s premier R&D organisations: C-DAC, SAMEER, and C-MET. Its first edition, Tec-verse 2025, was held on 27-28 June 2025 at Manekshaw Centre, New Delhi, as a unified platform to showcase and commercialise indigenous deep-tech solutions.',
                  style: const TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                    height: 1.55,
                    letterSpacing: -0.1,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Right Building Graphic with Deep-Tech Orbit Nodes
              Expanded(
                flex: 9,
                child: _buildBuildingIllustration(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tec-Verse logo shown beside the About section.
  Widget _buildBuildingIllustration() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Image.asset(
          'assets/images/tecverselogo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.public_rounded,
            color: Color(0xFF0284C7),
            size: 56,
          ),
        ),
      ),
    );
  }

  /// Detail Modal Sheet for C-DAC, SAMEER, and C-MET
  void _showOrgDetailsModal(
    BuildContext context, {
    required String name,
    required String title,
    required String mandate,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mandate,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
