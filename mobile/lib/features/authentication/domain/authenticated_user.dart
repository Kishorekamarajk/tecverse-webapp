/// Registration approval/verification status from backend.
enum RegistrationStatus {
  registered,
  pending,
  approved,
  cancelled;

  static RegistrationStatus fromString(String? value) {
    if (value == null) return RegistrationStatus.registered;
    switch (value.toLowerCase()) {
      case 'approved':
        return RegistrationStatus.approved;
      case 'pending':
        return RegistrationStatus.pending;
      case 'cancelled':
      case 'revoked':
        return RegistrationStatus.cancelled;
      default:
        return RegistrationStatus.registered;
    }
  }

  String get label {
    switch (this) {
      case RegistrationStatus.approved:
        return 'APPROVED';
      case RegistrationStatus.pending:
        return 'PENDING REVIEW';
      case RegistrationStatus.cancelled:
        return 'REVOKED';
      case RegistrationStatus.registered:
        return 'CONFIRMED';
    }
  }
}

/// Attendee Profile synchronized from the TEC-VERSE website registration database.
class UserProfile {
  final String id;
  final String referenceNumber; // 12-digit reference from tecverse_ticket_registrations
  final String officialName;
  final String email;
  final String mobile;
  final String category; // Academia, Central Government, State Government, Industry / Startup
  final String organization;
  final String designation;
  final String attendanceDays; // Day 1, Day 2, or Both Days
  final List<String> interests;
  final RegistrationStatus registrationStatus;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.referenceNumber,
    required this.officialName,
    required this.email,
    required this.mobile,
    required this.category,
    required this.organization,
    required this.designation,
    required this.attendanceDays,
    this.interests = const [],
    this.registrationStatus = RegistrationStatus.registered,
    this.avatarUrl,
  });

  String get firstName {
    if (officialName.isEmpty) return 'Attendee';
    final parts = officialName.trim().split(' ');
    // Handle titles like Dr., Prof., Shri
    if (parts.length > 1 &&
        (parts[0].endsWith('.') || parts[0].toLowerCase() == 'dr' || parts[0].toLowerCase() == 'prof')) {
      return parts[1];
    }
    return parts[0];
  }

  UserProfile copyWith({
    String? id,
    String? referenceNumber,
    String? officialName,
    String? email,
    String? mobile,
    String? category,
    String? organization,
    String? designation,
    String? attendanceDays,
    List<String>? interests,
    RegistrationStatus? registrationStatus,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      officialName: officialName ?? this.officialName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      category: category ?? this.category,
      organization: organization ?? this.organization,
      designation: designation ?? this.designation,
      attendanceDays: attendanceDays ?? this.attendanceDays,
      interests: interests ?? this.interests,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final interestsList = json['interests'] as List<dynamic>?;
    return UserProfile(
      id: json['id']?.toString() ?? json['referenceNumber']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ??
          json['reference_number']?.toString() ??
          json['id']?.toString() ??
          '',
      officialName: json['officialName']?.toString() ??
          json['official_name']?.toString() ??
          json['name']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Attendee',
      organization: json['organization']?.toString() ??
          json['organizationName']?.toString() ??
          json['collegeName']?.toString() ??
          'TEC-VERSE Attendee',
      designation: json['designation']?.toString() ??
          json['academiaRole']?.toString() ??
          'Delegate',
      attendanceDays: json['attendanceDays']?.toString() ??
          json['attendance_days']?.toString() ??
          '26–27 November 2026',
      interests: interestsList != null
          ? interestsList.map((e) => e.toString()).toList()
          : <String>[],
      registrationStatus: RegistrationStatus.fromString(
        json['registrationStatus']?.toString() ?? json['status']?.toString(),
      ),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
      'officialName': officialName,
      'email': email,
      'mobile': mobile,
      'category': category,
      'organization': organization,
      'designation': designation,
      'attendanceDays': attendanceDays,
      'interests': interests,
      'registrationStatus': registrationStatus.name,
      'avatarUrl': avatarUrl,
    };
  }
}

/// Authentication session response containing tokens and attendee identity.
class AuthTokens {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }
}

/// Combined Authenticated User state.
class AuthenticatedUser {
  final AuthTokens tokens;
  final UserProfile profile;

  const AuthenticatedUser({
    required this.tokens,
    required this.profile,
  });
}
