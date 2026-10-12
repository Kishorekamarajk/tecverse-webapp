import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../domain/location_models.dart';

/// Centralized Venue Location Repository and Navigation Service for TEC-VERSE 2026.
///
/// Uses verified GPS coordinates for Chennai Trade Centre (CTC), Nandambakkam.
class VenueLocationData {
  VenueLocationData._();

  /// Verified GPS Coordinates for Chennai Trade Centre, Nandambakkam, Chennai
  static const double venueLatitude = 13.0148;
  static const double venueLongitude = 80.1909;

  /// Centralized Event Venue Model
  static const EventVenue venue = EventVenue(
    name: 'Chennai Trade Centre',
    address: 'Chennai Trade Centre Complex, Mount Poonamallee Rd, CTC Complex, Nandambakkam, Chennai, Tamil Nadu 600089',
    area: 'Mount Poonamallee Rd, CTC Complex, Nandambakkam',
    city: 'Chennai',
    postalCode: '600089',
    latitude: venueLatitude,
    longitude: venueLongitude,
    eventDates: '26–27 November 2026',
    nearestMetro: 'Alandur Metro Interchange (4.2 km) / Guindy Metro (4.8 km)',
    nearestAirport: 'Chennai International Airport MAA (6.5 km)',
    landmark: 'Opposite to IDPL Colony & Near MIOT International Hospital',
  );

  /// Key Arrival Hubs in Chennai for easy manual origin selection
  static const List<GeoLocation> popularOrigins = [
    GeoLocation(
      name: 'Chennai International Airport (MAA)',
      latitude: 12.994112,
      longitude: 80.170866,
    ),
    GeoLocation(
      name: 'Guindy Metro & Railway Station',
      latitude: 13.008425,
      longitude: 80.213348,
    ),
    GeoLocation(
      name: 'Alandur Metro Interchange',
      latitude: 13.003928,
      longitude: 80.201389,
    ),
    GeoLocation(
      name: 'Puratchi Thalaivar Dr. MGR Central Railway Station',
      latitude: 13.082680,
      longitude: 80.275466,
    ),
    GeoLocation(
      name: 'Koyambedu CMBT Bus Terminus',
      latitude: 13.069412,
      longitude: 80.194723,
    ),
    GeoLocation(
      name: 'T. Nagar (Panagal Park)',
      latitude: 13.040182,
      longitude: 80.233682,
    ),
    GeoLocation(
      name: 'OMR Sholinganallur Tech Corridor',
      latitude: 12.901018,
      longitude: 80.227914,
    ),
    GeoLocation(
      name: 'Tambaram Railway Junction',
      latitude: 12.924900,
      longitude: 80.100000,
    ),
  ];

  /// Default starting location (Guindy Station hub) if GPS is pending
  static const GeoLocation defaultOrigin = GeoLocation(
    name: 'Guindy Metro Hub',
    latitude: 13.008425,
    longitude: 80.213348,
  );

  /// Calculates dynamic route estimates for all 4 transport modes
  static Map<TransportMode, RouteOption> calculateRoutes({
    required GeoLocation origin,
  }) {
    final straightLineKm = origin.distanceTo(venue.location);
    // Real road distance in Chennai is typically 1.25x to 1.35x straight line
    final roadDistanceKm = (straightLineKm * 1.28).clamp(0.8, 80.0);

    return {
      TransportMode.driving: _buildRouteOption(
        mode: TransportMode.driving,
        distanceKm: roadDistanceKm,
        routeSummary: roadDistanceKm < 8
            ? 'Via Mount Poonamallee High Rd (Fastest)'
            : 'Via Kathipara Flyover & Grand Southern Trunk Rd',
        trafficStatus: 'Usual Traffic',
        turnHighlights: [
          'Head towards Kathipara Grade Separator',
          'Take the exit onto Mount Poonamallee High Rd towards Porur',
          'Pass MIOT International Hospital on left',
          'Arrive at Nandambakkam, Tamil Nadu 600089 on right',
        ],
      ),
      TransportMode.twoWheeler: _buildRouteOption(
        mode: TransportMode.twoWheeler,
        distanceKm: roadDistanceKm * 0.98,
        routeSummary: 'Via Inner Ring Road & Mount Poonamallee Service Lane',
        trafficStatus: 'Brisk Flow',
        turnHighlights: [
          'Follow Guindy-Porur Link arterial road',
          'Use dedicated two-wheeler lane on Mount Poonamallee Bridge',
          'Enter through Gate 2 Attendee Two-Wheeler Parking',
        ],
      ),
      TransportMode.publicTransit: _buildRouteOption(
        mode: TransportMode.publicTransit,
        distanceKm: roadDistanceKm * 1.12,
        routeSummary: 'Chennai Metro Blue Line → Alandur / Guindy → Feeder MTC Bus 54/88',
        trafficStatus: 'Every 6-8 mins',
        turnHighlights: [
          'Board Chennai Metro towards Alandur or Guindy Station',
          'Transfer to MTC AC Bus Route 54, 88, or 154 towards Porur/Poonamallee',
          'De-board at Nandambakkam Bus Stop, 600089 (Directly outside venue)',
        ],
      ),
      TransportMode.walking: _buildRouteOption(
        mode: TransportMode.walking,
        distanceKm: roadDistanceKm * 0.95,
        routeSummary: 'Pedestrian footpath along Mount Poonamallee Road',
        trafficStatus: 'Clear Walkway',
        turnHighlights: [
          'Walk west along shaded pedestrian sidewalk',
          'Use signalized pedestrian crossing near IDPL complex',
          'Enter through Main Pedestrian Security Portico',
        ],
      ),
    };
  }

  static RouteOption _buildRouteOption({
    required TransportMode mode,
    required double distanceKm,
    required String routeSummary,
    required String trafficStatus,
    required List<String> turnHighlights,
  }) {
    final speed = mode.averageSpeedKmh;
    final hours = distanceKm / speed;
    final minutes = (hours * 60.0).round().clamp(2, 240);

    return RouteOption(
      mode: mode,
      distanceKm: (distanceKm * 10).round() / 10.0,
      durationMinutes: minutes,
      routeSummary: routeSummary,
      trafficStatus: trafficStatus,
      turnHighlights: turnHighlights,
    );
  }

  /// Direct Google Maps turn-by-turn navigation for Chennai Trade Centre, Nandambakkam
  static Future<bool> openGoogleMapsDirections({
    GeoLocation? origin,
    TransportMode mode = TransportMode.driving,
  }) async {
    const destinationQuery = 'Chennai+Trade+Centre,+Nandambakkam,+Chennai';
    final travelMode = mode.googleMapsTravelMode;

    final Uri googleMapsDirUrl;
    if (origin != null) {
      // Directions from specified origin (e.g. Airport, Guindy, or local GPS)
      googleMapsDirUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=$destinationQuery&travelmode=$travelMode',
      );
    } else {
      // Search & View Chennai Trade Centre Place Card with directions button
      googleMapsDirUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$destinationQuery',
      );
    }

    try {
      if (await canLaunchUrl(googleMapsDirUrl)) {
        return await launchUrl(googleMapsDirUrl, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(googleMapsDirUrl, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        return await launchUrl(googleMapsDirUrl, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }

  /// Launches turn-by-turn navigation in native Google Maps, Apple Maps, or Web
  static Future<bool> openNativeDirections({
    GeoLocation? origin,
    TransportMode mode = TransportMode.driving,
  }) async {
    const destLat = venueLatitude;
    const destLng = venueLongitude;

    // Build platform-specific directions URL on iOS
    if (!kIsWeb && Platform.isIOS) {
      Uri url;
      if (origin != null) {
        url = Uri.parse(
          'https://maps.apple.com/?saddr=${origin.latitude},${origin.longitude}&daddr=Chennai+Trade+Centre,+Nandambakkam&ll=$destLat,$destLng&dirflg=${mode == TransportMode.walking ? "w" : "d"}',
        );
      } else {
        url = Uri.parse('https://maps.apple.com/?daddr=Chennai+Trade+Centre,+Nandambakkam&ll=$destLat,$destLng');
      }

      try {
        if (await canLaunchUrl(url)) {
          return await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // Default to Google Maps Directions
    return openGoogleMapsDirections(origin: origin, mode: mode);
  }

  /// Opens Google Maps view for Chennai Trade Centre
  static Future<bool> openInGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Chennai+Trade+Centre,+Nandambakkam,+Chennai',
    );
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }
}
