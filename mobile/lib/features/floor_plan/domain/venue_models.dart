import 'package:flutter/material.dart';

/// Types of facilities available throughout Chennai Trade Centre (CTC)
enum FacilityType {
  mainEntrance,
  registrationDesk,
  infoDesk,
  foodCourt,
  restroom,
  firstAid,
  emergencyExit,
  parkingArea,
  helpDesk,
}

extension FacilityTypeExtension on FacilityType {
  String get displayName {
    switch (this) {
      case FacilityType.mainEntrance:
        return 'Main Entrance';
      case FacilityType.registrationDesk:
        return 'Registration Desk';
      case FacilityType.infoDesk:
        return 'Information Desk';
      case FacilityType.foodCourt:
        return 'Food Court / Cafeteria';
      case FacilityType.restroom:
        return 'Restrooms';
      case FacilityType.firstAid:
        return 'First Aid & Medical';
      case FacilityType.emergencyExit:
        return 'Emergency Exit';
      case FacilityType.parkingArea:
        return 'Parking Area';
      case FacilityType.helpDesk:
        return 'Help Desk';
    }
  }

  IconData get icon {
    switch (this) {
      case FacilityType.mainEntrance:
        return Icons.login_rounded;
      case FacilityType.registrationDesk:
        return Icons.how_to_reg_rounded;
      case FacilityType.infoDesk:
        return Icons.info_outline_rounded;
      case FacilityType.foodCourt:
        return Icons.restaurant_rounded;
      case FacilityType.restroom:
        return Icons.wc_rounded;
      case FacilityType.firstAid:
        return Icons.medical_services_rounded;
      case FacilityType.emergencyExit:
        return Icons.emergency_share_rounded;
      case FacilityType.parkingArea:
        return Icons.local_parking_rounded;
      case FacilityType.helpDesk:
        return Icons.support_agent_rounded;
    }
  }

  Color get color {
    switch (this) {
      case FacilityType.mainEntrance:
        return const Color(0xFF00F2FE); // Cyan
      case FacilityType.registrationDesk:
        return const Color(0xFF38BDF8); // Sky blue
      case FacilityType.infoDesk:
        return const Color(0xFF818CF8); // Indigo
      case FacilityType.foodCourt:
        return const Color(0xFFF59E0B); // Amber
      case FacilityType.restroom:
        return const Color(0xFF94A3B8); // Slate
      case FacilityType.firstAid:
        return const Color(0xFFEF4444); // Red
      case FacilityType.emergencyExit:
        return const Color(0xFF10B981); // Emerald
      case FacilityType.parkingArea:
        return const Color(0xFF64748B); // Slate
      case FacilityType.helpDesk:
        return const Color(0xFF3B82F6); // Blue
    }
  }
}

/// Facility item placed on the venue floor map
class FacilityItem {
  final String id;
  final String name;
  final FacilityType type;
  final Offset position; // Relative coordinate on the venue map (0..1000)
  final String description;

  const FacilityItem({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.description = '',
  });
}

/// Technology category zone inside an exhibition hall
class TechnologyZone {
  final String id;
  final String name;
  final String hallId;
  final Color color;
  final List<String> sessions;

  const TechnologyZone({
    required this.id,
    required this.name,
    required this.hallId,
    required this.color,
    this.sessions = const [],
  });
}

/// Exhibition Hall / Convention Area represented on the map
class Hall {
  final String id;
  final String name;
  final String number;
  final Rect bounds; // Bounding box on the map canvas
  final List<TechnologyZone> zones;
  final List<String> nearbyFacilities;
  final String subtitle;
  final bool isConvention;
  final Color accentColor;

  const Hall({
    required this.id,
    required this.name,
    required this.number,
    required this.bounds,
    required this.zones,
    required this.nearbyFacilities,
    required this.subtitle,
    this.isConvention = false,
    this.accentColor = const Color(0xFF00F2FE),
  });

  Offset get center => bounds.center;
}

/// Wayfinding navigation route with step-by-step guidance
class NavigationRoute {
  final String destinationName;
  final String destinationHall;
  final String? destinationBooth;
  final List<Offset> waypoints;
  final double distanceMeters;
  final int estimatedWalkingMinutes;
  final List<String> steps;

  const NavigationRoute({
    required this.destinationName,
    required this.destinationHall,
    this.destinationBooth,
    required this.waypoints,
    required this.distanceMeters,
    required this.estimatedWalkingMinutes,
    required this.steps,
  });
}

/// Venue model for Chennai Trade Centre
class Venue {
  final String id;
  final String name;
  final String address;
  final String city;
  final String postalCode;
  final List<Hall> halls;
  final List<FacilityItem> facilities;
  final String? officialFloorPlanUrl;
  final String? officialFloorPlanAsset;

  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.halls,
    required this.facilities,
    this.officialFloorPlanUrl,
    this.officialFloorPlanAsset,
  });
}
