import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/digital_event_pass.dart';

/// Detailed Delegate Information Generator Sheet shown upon scanning a Barcode / QR Code.
///
/// Neatly structures and presents:
/// - Security Verification Status & Digital Signature Hash
/// - Delegate Identity, Name, Designation & Institution
/// - Official Reference ID & Pass Serial
/// - Zone Access Privileges & Event Entitlements
/// - Contact & Geographic Information
/// - Registered Technology Domains
/// - Interactive Gate Check-in & Badge Slip generation actions
class DelegateVerificationSheet extends StatefulWidget {
  final DigitalEventPass pass;
  final String? scannedRawData;
  final VoidCallback? onCheckedIn;

  const DelegateVerificationSheet({
    super.key,
    required this.pass,
    this.scannedRawData,
    this.onCheckedIn,
  });

  /// Static helper to conveniently open the modal from anywhere
  static Future<void> show(
    BuildContext context, {
    required DigitalEventPass pass,
    String? scannedRawData,
    VoidCallback? onCheckedIn,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DelegateVerificationSheet(
        pass: pass,
        scannedRawData: scannedRawData,
        onCheckedIn: onCheckedIn,
      ),
    );
  }

  @override
  State<DelegateVerificationSheet> createState() =>
      _DelegateVerificationSheetState();
}

class _DelegateVerificationSheetState extends State<DelegateVerificationSheet> {
  late PassStatus _currentStatus;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.pass.status;
  }

  void _handleGateCheckIn() async {
    setState(() => _isCheckingIn = true);
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isCheckingIn = false;
        _currentStatus = PassStatus.used;
      });
      widget.onCheckedIn?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pass = widget.pass;
    final initials = pass.holderName.isNotEmpty
        ? pass.holderName
            .trim()
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'TV';

    final isVerified = _currentStatus == PassStatus.active ||
        _currentStatus == PassStatus.used;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Modal Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'DELEGATE CREDENTIAL VERIFICATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Official Entry & Attendee Information',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Scrollable Body Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    // 1. Status Banner
                    _buildStatusBanner(isVerified),

                    const SizedBox(height: 14),

                    // 2. Primary Attendee Identity Card
                    _buildAttendeeIdentityCard(pass, initials),

                    const SizedBox(height: 14),

                    // 3. Official Registration & Security Details Box
                    _buildRegistrationDetailsBox(pass),

                    const SizedBox(height: 14),

                    // 4. Access Entitlements & Privileges Grid
                    _buildAccessEntitlementsCard(pass),

                    const SizedBox(height: 14),

                    // 5. Technology Domains & Interests
                    _buildTechnologyDomainsCard(),

                    const SizedBox(height: 14),

                    // 6. Contact & Venue Logistics Card
                    _buildLogisticsCard(pass),

                    const SizedBox(height: 20),

                    // 7. Gate Action Buttons (Check-in / Print Badge Slip)
                    _buildActionButtons(context, pass),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 1. Top Security Verification Status Banner
  Widget _buildStatusBanner(bool isVerified) {
    final isCheckedIn = _currentStatus == PassStatus.used;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCheckedIn
            ? const Color(0xFFEFF6FF)
            : (isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCheckedIn
              ? const Color(0xFFBAE6FD)
              : (isVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCheckedIn
                  ? const Color(0xFF0284C7)
                  : (isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckedIn
                  ? Icons.how_to_reg_rounded
                  : (isVerified ? Icons.check_circle_rounded : Icons.cancel_rounded),
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckedIn
                      ? 'GATE ENTRY RECORDED • ATTENDEE ACTIVE'
                      : (isVerified
                          ? 'SECURITY VERIFIED • VALID PASS'
                          : 'PASS STATUS INACTIVE'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: isCheckedIn
                        ? const Color(0xFF0369A1)
                        : (isVerified ? const Color(0xFF047857) : const Color(0xFFB91C1C)),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Barcode Signature Validated • Gate 1 Fast-Track • Chennai Trade Centre',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isCheckedIn
                        ? const Color(0xFF0284C7)
                        : (isVerified ? const Color(0xFF059669) : const Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Primary Attendee Identity Card
  Widget _buildAttendeeIdentityCard(DigitalEventPass pass, String initials) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Avatar / Photo Badge
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Name, Role & Organization
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pass.holderName.isNotEmpty
                            ? pass.holderName
                            : 'Registered Delegate',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF0284C7),
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                if (pass.designation.isNotEmpty)
                  Text(
                    pass.designation,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 2),

                Text(
                  pass.organization.isNotEmpty
                      ? pass.organization
                      : 'MeitY R&D Consortium / Scientific Delegate',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD4BE)),
                  ),
                  child: Text(
                    pass.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEA580C),
                      letterSpacing: 0.4,
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

  /// 3. Registration & Security Cryptographic Info Box
  Widget _buildRegistrationDetailsBox(DigitalEventPass pass) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, size: 16, color: Color(0xFFEA580C)),
              SizedBox(width: 8),
              Text(
                'REGISTRATION & SECURITY RECORD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEA580C),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildInfoRow('Reference No', pass.attendeeId.isNotEmpty ? pass.attendeeId : 'TEC2026-680410', isBold: true),
          _buildInfoRow('Pass ID', pass.passId),
          _buildInfoRow('Registration Type', pass.category),
          _buildInfoRow('Attendance Mode', pass.attendanceDays),
          _buildInfoRow('Security Token', pass.qrToken.length > 24 ? '${pass.qrToken.substring(0, 24)}...' : pass.qrToken),
        ],
      ),
    );
  }

  /// 4. Access Entitlements Card
  Widget _buildAccessEntitlementsCard(DigitalEventPass pass) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.door_sliding_rounded, size: 16, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'ZONE ACCESS & EVENT PRIVILEGES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPrivilegePill('🏛️ Grand Convention Foyer', true),
              _buildPrivilegePill('🚀 Exhibition Halls 1, 2 & 3', true),
              _buildPrivilegePill('🎙️ Keynote Plenary Auditorium', true),
              _buildPrivilegePill('☕ Executive Delegate Lunch & Kit', true),
              _buildPrivilegePill('💼 B2B Networking Lounge', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegePill(String label, bool isGranted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Technology Domains & Interests
  Widget _buildTechnologyDomainsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.hub_rounded, size: 16, color: Color(0xFF9333EA)),
              SizedBox(width: 8),
              Text(
                'REGISTERED TECHNOLOGY DOMAINS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9333EA),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildDomainChip('AI & Supercomputing', const Color(0xFF0284C7)),
              _buildDomainChip('Semiconductors & Materials', const Color(0xFFEA580C)),
              _buildDomainChip('Quantum & Deep-Tech', const Color(0xFF9333EA)),
              _buildDomainChip('Microwave & Radar Tech', const Color(0xFF059669)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  /// 6. Contact & Venue Logistics Card
  Widget _buildLogisticsCard(DigitalEventPass pass) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pin_drop_outlined, size: 16, color: Color(0xFFEA580C)),
              SizedBox(width: 8),
              Text(
                'CONCLAVE VENUE & DATES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEA580C),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _buildInfoRow('Venue', 'Chennai Trade Centre, Nandambakkam'),
          _buildInfoRow('Conference Dates', '26 – 27 November 2026'),
          _buildInfoRow('Organised By', 'Consortium of Scientific Societies (MeitY)'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Text(':  ', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 7. Action Buttons (Check-in & Badge Slip)
  Widget _buildActionButtons(BuildContext context, DigitalEventPass pass) {
    final isCheckedIn = _currentStatus == PassStatus.used;

    return Column(
      children: [
        // Primary Gate Check-in Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCheckedIn
                  ? const Color(0xFF059669)
                  : const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            icon: _isCheckingIn
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isCheckedIn ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                    size: 20,
                  ),
            label: Text(
              isCheckedIn ? 'Entry Verified & Recorded' : 'Confirm Gate Entry Check-In',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            onPressed: isCheckedIn || _isCheckingIn ? null : _handleGateCheckIn,
          ),
        ),

        const SizedBox(height: 10),

        // Secondary Fast-Track Badge Slip Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text(
              'Print Delegate Badge Slip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0284C7),
                  content: Text(
                    'Badge printing slip sent to Registration Desk for ${pass.holderName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
