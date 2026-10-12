/// Pass validity and verification status issued by the backend.
enum PassStatus {
  active,
  used,
  revoked,
  expired;

  static PassStatus fromString(String? value) {
    if (value == null) return PassStatus.active;
    switch (value.toLowerCase()) {
      case 'used':
        return PassStatus.used;
      case 'revoked':
        return PassStatus.revoked;
      case 'expired':
        return PassStatus.expired;
      default:
        return PassStatus.active;
    }
  }

  String get label {
    switch (this) {
      case PassStatus.active:
        return 'ACTIVE & VALID';
      case PassStatus.used:
        return 'CHECKED IN';
      case PassStatus.revoked:
        return 'REVOKED';
      case PassStatus.expired:
        return 'EXPIRED';
    }
  }
}

/// Official Unique Digital Event Pass model.
///
/// Tied 1-to-1 with the registered website attendee.
/// The pass identity and cryptographic QR token originate from the authoritative backend.
class DigitalEventPass {
  final String passId; // e.g. "TV26-PASS-88219"
  final String attendeeId; // 12-digit reference number from website registration
  final String userId;
  final String holderName;
  final String organization;
  final String designation;
  final String category;
  final String eventName;
  final String eventDates;
  final String venue;
  final String attendanceDays;
  final String qrToken; // Opaque signed token: "TECVERSE26:TV26-PASS-88219:202611261042:SEC89F"
  final PassStatus status;
  final DateTime issuedAt;
  final DateTime? checkedInAt;

  const DigitalEventPass({
    required this.passId,
    required this.attendeeId,
    required this.userId,
    required this.holderName,
    required this.organization,
    required this.designation,
    required this.category,
    this.eventName = 'TEC-VERSE 2026',
    this.eventDates = '26–27 NOVEMBER 2026',
    this.venue = 'NANDAMBAKKAM, TAMIL NADU 600089',
    required this.attendanceDays,
    required this.qrToken,
    this.status = PassStatus.active,
    required this.issuedAt,
    this.checkedInAt,
  });

  factory DigitalEventPass.fromJson(Map<String, dynamic> json) {
    return DigitalEventPass(
      passId: json['passId']?.toString() ?? json['id']?.toString() ?? 'TV26-PASS-00000',
      attendeeId: json['attendeeId']?.toString() ?? json['referenceNumber']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? json['name']?.toString() ?? '',
      organization: json['organization']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Delegate',
      eventName: json['eventName']?.toString() ?? 'TEC-VERSE 2026',
      eventDates: json['eventDates']?.toString() ?? '26–27 NOVEMBER 2026',
      venue: json['venue']?.toString() ?? 'CHENNAI TRADE CENTRE, NANDAMBAKKAM, CHENNAI 600089',
      attendanceDays: json['attendanceDays']?.toString() ?? 'Both Days (26 & 27 Nov 2026)',
      qrToken: json['qrToken']?.toString() ?? 'TECVERSE26:${json['passId']}',
      status: PassStatus.fromString(json['status']?.toString()),
      issuedAt: json['issuedAt'] != null
          ? DateTime.tryParse(json['issuedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.tryParse(json['checkedInAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passId': passId,
      'attendeeId': attendeeId,
      'userId': userId,
      'holderName': holderName,
      'organization': organization,
      'designation': designation,
      'category': category,
      'eventName': eventName,
      'eventDates': eventDates,
      'venue': venue,
      'attendanceDays': attendanceDays,
      'qrToken': qrToken,
      'status': status.name,
      'issuedAt': issuedAt.toIso8601String(),
      'checkedInAt': checkedInAt?.toIso8601String(),
    };
  }

  DigitalEventPass copyWith({
    PassStatus? status,
    DateTime? checkedInAt,
  }) {
    return DigitalEventPass(
      passId: passId,
      attendeeId: attendeeId,
      userId: userId,
      holderName: holderName,
      organization: organization,
      designation: designation,
      category: category,
      eventName: eventName,
      eventDates: eventDates,
      venue: venue,
      attendanceDays: attendanceDays,
      qrToken: qrToken,
      status: status ?? this.status,
      issuedAt: issuedAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
    );
  }

  /// Web Verification URL encoded directly into the QR Code.
  /// When scanned via Google Lens, Apple Camera, or any Barcode/QR Scanner,
  /// the phone immediately prompts to open this official Delegate Credential Verification web page.
  String get scannableInfo {
    final baseUrl = 'https://ngypr123.bosschn.in/tecverse';
    final pId = Uri.encodeComponent(passId);
    final ref = Uri.encodeComponent(attendeeId.isNotEmpty ? attendeeId : passId);
    final tok = Uri.encodeComponent(qrToken);
    return '$baseUrl/verify?passId=$pId&ref=$ref&token=$tok';
  }
}
