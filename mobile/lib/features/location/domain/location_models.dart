import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Transport modes supported for travelling to Chennai Trade Centre
enum TransportMode {
  driving,
  twoWheeler,
  publicTransit,
  walking,
}

extension TransportModeExtension on TransportMode {
  String get displayName {
    switch (this) {
      case TransportMode.driving:
        return 'Driving';
      case TransportMode.twoWheeler:
        return 'Two Wheeler';
      case TransportMode.publicTransit:
        return 'Public Transit';
      case TransportMode.walking:
        return 'Walking';
    }
  }

  IconData get icon {
    switch (this) {
      case TransportMode.driving:
        return Icons.directions_car_rounded;
      case TransportMode.twoWheeler:
        return Icons.two_wheeler_rounded;
      case TransportMode.publicTransit:
        return Icons.directions_subway_rounded;
      case TransportMode.walking:
        return Icons.directions_walk_rounded;
    }
  }

  /// Average speed in km/h considering Chennai traffic
  double get averageSpeedKmh {
    switch (this) {
      case TransportMode.driving:
        return 28.0; // Chennai arterial road traffic average
      case TransportMode.twoWheeler:
        return 34.0; // Two-wheelers navigate traffic bottlenecks faster
      case TransportMode.publicTransit:
        return 25.0; // Metro + feeder bus transfer time
      case TransportMode.walking:
        return 4.5;  // Average walking pace
    }
  }

  String get googleMapsTravelMode {
    switch (this) {
      case TransportMode.driving:
        return 'driving';
      case TransportMode.twoWheeler:
        return 'two_wheeler';
      case TransportMode.publicTransit:
        return 'transit';
      case TransportMode.walking:
        return 'walking';
    }
  }
}

/// Geographic coordinates with distance calculator
class GeoLocation {
  final double latitude;
  final double longitude;
  final String name;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  /// Calculates geodesic distance in kilometers using the Haversine formula
  double distanceTo(GeoLocation other) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(other.latitude - latitude);
    final dLon = _degreesToRadians(other.longitude - longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(latitude)) *
            math.cos(_degreesToRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}

/// Route summary for a specific transport mode
class RouteOption {
  final TransportMode mode;
  final double distanceKm;
  final int durationMinutes;
  final String routeSummary;
  final String trafficStatus;
  final List<String> turnHighlights;

  const RouteOption({
    required this.mode,
    required this.distanceKm,
    required this.durationMinutes,
    required this.routeSummary,
    this.trafficStatus = 'Moderate Traffic',
    required this.turnHighlights,
  });
}

/// Centralized Venue Configuration
class EventVenue {
  final String name;
  final String address;
  final String area;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String eventDates;
  final String nearestMetro;
  final String nearestAirport;
  final String landmark;

  const EventVenue({
    required this.name,
    required this.address,
    required this.area,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.eventDates,
    required this.nearestMetro,
    required this.nearestAirport,
    required this.landmark,
  });

  GeoLocation get location => GeoLocation(
        latitude: latitude,
        longitude: longitude,
        name: name,
      );

  String get fullAddress => '$name, $area, $city – $postalCode';
}
