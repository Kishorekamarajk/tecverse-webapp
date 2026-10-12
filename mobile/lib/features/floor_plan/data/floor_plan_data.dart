import 'package:flutter/material.dart';
import '../domain/venue_models.dart';

/// Centralized Master Data Repository for Chennai Trade Centre (CTC) Floor Plan.
///
/// Designed to be completely configurable so organizers can easily update booth assignments,
/// hall configurations, official PDF links, and facilities without refactoring the UI.
class FloorPlanData {
  FloorPlanData._();

  // Map canvas coordinate system dimensions (1000 x 1400 virtual grid)
  static const double canvasWidth = 1000.0;
  static const double canvasHeight = 1400.0;

  // Venue coordinates
  static const Offset mainEntranceCoord = Offset(500, 1340);
  static const Offset registrationCoord = Offset(500, 1230);
  static const Offset centralHubCoord = Offset(500, 920);
  static const Offset phase2HubCoord = Offset(500, 480);

  /// Official floor plan URL or asset path (configured by organizers).
  /// Set to null or non-empty string when the official government PDF is published.
  static const String? officialFloorPlanUrl = null;
  static const String? officialFloorPlanAsset = null;

  /// Technology Category Color Palette
  static const Color colorAiHpc = Color(0xFF00F2FE); // Electric Cyan
  static const Color colorQuantum = Color(0xFFA855F7); // Violet
  static const Color colorCybersecurity = Color(0xFFF59E0B); // Amber / Gold
  static const Color colorSemiconductors = Color(0xFF0A84FF); // Electric Blue
  static const Color colorRobotics = Color(0xFFF43F5E); // Rose
  static const Color colorIoT = Color(0xFF10B981); // Emerald
  static const Color colorElectronics = Color(0xFF14B8A6); // Teal
  static const Color colorEmergingTech = Color(0xFFEC4899); // Neon Pink

  static const List<TechnologyZone> allTechnologyZones = [
    TechnologyZone(
      id: 'tz-ai',
      name: 'AI & Supercomputing',
      hallId: 'hall-1',
      color: colorAiHpc,
      sessions: [
        'National AI Mission & PARAM Supercomputing Frontiers',
        'IndiaAI Sovereign GPU Compute Infrastructure',
        'Large Language Model Optimization for Edge Devices',
      ],
    ),
    TechnologyZone(
      id: 'tz-quantum',
      name: 'Quantum Technologies',
      hallId: 'hall-1',
      color: colorQuantum,
      sessions: [
        'National Quantum Mission: Quantum Communications & QKD',
        'Superconducting Qubits & Cryogenic Control Systems',
      ],
    ),
    TechnologyZone(
      id: 'tz-semicon',
      name: 'Semiconductors & VLSI',
      hallId: 'hall-1',
      color: colorSemiconductors,
      sessions: [
        'India Semiconductor Mission: Indigenous Silicon & RISC-V VEGA',
        '28nm Fab Fabrication & Packaging Ecosystem',
      ],
    ),
    TechnologyZone(
      id: 'tz-cyber',
      name: 'Cybersecurity',
      hallId: 'hall-2',
      color: colorCybersecurity,
      sessions: [
        'Critical Information Infrastructure & Zero Trust Defense',
        'National Cyber Crisis Management & Threat Intel Feeds',
      ],
    ),
    TechnologyZone(
      id: 'tz-robotics',
      name: 'Robotics & Automation',
      hallId: 'hall-2',
      color: colorRobotics,
      sessions: [
        'Autonomous Mobile Robots in Industrial Logistics',
        'Exoskeletons & Micro-manipulators for Precision Tech',
      ],
    ),
    TechnologyZone(
      id: 'tz-iot',
      name: 'IoT & Embedded Systems',
      hallId: 'hall-3',
      color: colorIoT,
      sessions: [
        '5G/6G Sensor Arrays & Ultra-Low Power Mesh Networks',
        'Smart Grid Monitoring & Industrial SCADA Security',
      ],
    ),
    TechnologyZone(
      id: 'tz-electronics',
      name: 'Advanced Electronics',
      hallId: 'hall-4',
      color: colorElectronics,
      sessions: [
        'GaN Microwave Transistors & High-Power RF Amplifiers',
        'Printed Circuit Board Manufacturing & High-Density Interconnects',
      ],
    ),
    TechnologyZone(
      id: 'tz-emerging',
      name: 'Emerging Technologies',
      hallId: 'hall-3',
      color: colorEmergingTech,
      sessions: [
        'Neuromorphic Computing & Photonic Interconnects',
        'Synthetic Biology & Bio-Sensor Integration',
      ],
    ),
  ];

  /// Comprehensive Exhibition Halls and Convention Areas
  static const List<Hall> allHalls = [
    // Phase 1 Main Exhibition Complex (Lower Section)
    Hall(
      id: 'hall-1',
      name: 'Hall 1 — Supercomputing & Silicon',
      number: '1',
      bounds: Rect.fromLTWH(80, 970, 370, 180),
      zones: [
        TechnologyZone(
          id: 'tz-ai-h1',
          name: 'AI & Supercomputing',
          hallId: 'hall-1',
          color: colorAiHpc,
        ),
        TechnologyZone(
          id: 'tz-quantum-h1',
          name: 'Quantum Technologies',
          hallId: 'hall-1',
          color: colorQuantum,
        ),
        TechnologyZone(
          id: 'tz-semicon-h1',
          name: 'Semiconductor & VLSI',
          hallId: 'hall-1',
          color: colorSemiconductors,
        ),
      ],
      nearbyFacilities: ['Registration Desk', 'Information Desk', 'Restrooms (Phase 1)', 'First Aid Hub'],
      subtitle: 'National AI Mission, PARAM Supercomputers, RISC-V VEGA & India Semiconductor Mission',
      accentColor: colorAiHpc,
    ),
    Hall(
      id: 'hall-2',
      name: 'Hall 2 — Security & Robotics',
      number: '2',
      bounds: Rect.fromLTWH(550, 970, 370, 180),
      zones: [
        TechnologyZone(
          id: 'tz-cyber-h2',
          name: 'Cybersecurity',
          hallId: 'hall-2',
          color: colorCybersecurity,
        ),
        TechnologyZone(
          id: 'tz-embedded-h2',
          name: 'Embedded Systems',
          hallId: 'hall-2',
          color: colorElectronics,
        ),
        TechnologyZone(
          id: 'tz-robotics-h2',
          name: 'Robotics & Automation',
          hallId: 'hall-2',
          color: colorRobotics,
        ),
      ],
      nearbyFacilities: ['Registration Desk', 'Food Court (South)', 'Restrooms (East Wing)'],
      subtitle: 'Zero-Trust Cyber Defense, Industrial Cobots, SAMEER RF Testing & Space Robotics',
      accentColor: colorCybersecurity,
    ),
    Hall(
      id: 'hall-3',
      name: 'Hall 3 — IoT & Future Tech',
      number: '3',
      bounds: Rect.fromLTWH(80, 740, 370, 170),
      zones: [
        TechnologyZone(
          id: 'tz-iot-h3',
          name: 'IoT & Smart Systems',
          hallId: 'hall-3',
          color: colorIoT,
        ),
        TechnologyZone(
          id: 'tz-electronics-h3',
          name: 'Advanced Electronics',
          hallId: 'hall-3',
          color: colorElectronics,
        ),
        TechnologyZone(
          id: 'tz-emerging-h3',
          name: 'Emerging Technologies',
          hallId: 'hall-3',
          color: colorEmergingTech,
        ),
      ],
      nearbyFacilities: ['Central Restrooms', 'Cafe Lounge', 'Emergency Exit 3'],
      subtitle: '5G Sensor Meshes, C-MET Electronic Materials, Circular Electronics & Nanotech',
      accentColor: colorIoT,
    ),
    Hall(
      id: 'hall-4',
      name: 'Hall 4 — Power & Green Tech',
      number: '4',
      bounds: Rect.fromLTWH(550, 740, 370, 170),
      zones: [
        TechnologyZone(
          id: 'tz-power-h4',
          name: 'Power Electronics',
          hallId: 'hall-4',
          color: colorSemiconductors,
        ),
        TechnologyZone(
          id: 'tz-green-h4',
          name: 'Green Tech & Circularity',
          hallId: 'hall-4',
          color: colorIoT,
        ),
      ],
      nearbyFacilities: ['Food Court (South)', 'Restrooms (East Wing)', 'Emergency Exit 4'],
      subtitle: 'GaN & SiC Power Converters, Solar Micro-inverters & Lithium Battery Recycling',
      accentColor: colorElectronics,
    ),

    // Phase 2 Expansion Complex (Upper Section)
    Hall(
      id: 'hall-5',
      name: 'Hall 5 — Defence & Aerospace',
      number: '5',
      bounds: Rect.fromLTWH(80, 510, 370, 170),
      zones: [
        TechnologyZone(
          id: 'tz-defence-h5',
          name: 'Aerospace & Radar',
          hallId: 'hall-5',
          color: colorSemiconductors,
        ),
        TechnologyZone(
          id: 'tz-avionics-h5',
          name: 'Avionics & Drone Tech',
          hallId: 'hall-5',
          color: colorAiHpc,
        ),
      ],
      nearbyFacilities: ['Phase 2 Restrooms', 'Medical First Aid 2', 'Emergency Exit 5'],
      subtitle: 'AESA Radars, Satellite Payloads, Indigenous Drone Swarms & NavIC Chips',
      accentColor: colorSemiconductors,
    ),
    Hall(
      id: 'hall-6',
      name: 'Hall 6 — MedTech & Bio-Sensors',
      number: '6',
      bounds: Rect.fromLTWH(550, 510, 370, 170),
      zones: [
        TechnologyZone(
          id: 'tz-med-h6',
          name: 'Digital Health & MedTech',
          hallId: 'hall-6',
          color: colorRobotics,
        ),
        TechnologyZone(
          id: 'tz-bio-h6',
          name: 'Bio-Informatics',
          hallId: 'hall-6',
          color: colorEmergingTech,
        ),
      ],
      nearbyFacilities: ['North Food Pavilion', 'Restrooms (Phase 2)', 'Emergency Exit 6'],
      subtitle: 'AI Diagnostic Imaging, Telemedicine Appliances & Wearable Biosensors',
      accentColor: colorRobotics,
    ),
    Hall(
      id: 'hall-7',
      name: 'Hall 7 — Mobility & EV Tech',
      number: '7',
      bounds: Rect.fromLTWH(80, 280, 370, 170),
      zones: [
        TechnologyZone(
          id: 'tz-ev-h7',
          name: 'Smart Mobility & EV',
          hallId: 'hall-7',
          color: colorCybersecurity,
        ),
        TechnologyZone(
          id: 'tz-battery-h7',
          name: 'Solid State Batteries',
          hallId: 'hall-7',
          color: colorIoT,
        ),
      ],
      nearbyFacilities: ['West Gate Exit', 'Restrooms (North)', 'Charging Pods'],
      subtitle: 'ADAS Edge Processors, BMS Micro-controllers & Fast Charging Protocol Labs',
      accentColor: colorCybersecurity,
    ),
    Hall(
      id: 'hall-8',
      name: 'Hall 8 — Startup Hub & Incubator',
      number: '8',
      bounds: Rect.fromLTWH(550, 280, 370, 170),
      zones: [
        TechnologyZone(
          id: 'tz-startups-h8',
          name: 'DeepTech Startups',
          hallId: 'hall-8',
          color: colorEmergingTech,
        ),
        TechnologyZone(
          id: 'tz-incubator-h8',
          name: 'VC & Angel Arena',
          hallId: 'hall-8',
          color: colorAiHpc,
        ),
      ],
      nearbyFacilities: ['North Food Pavilion', 'Investor Lounge', 'Emergency Exit 8'],
      subtitle: 'DeepTech Founders, Seed Stage Demonstrators, Angel Matchmaking & Demos',
      accentColor: colorEmergingTech,
    ),

    // Convention Centre Complex (Top Grand Apex)
    Hall(
      id: 'hall-convention',
      name: 'Grand Convention Centre',
      number: 'CC',
      bounds: Rect.fromLTWH(180, 60, 640, 160),
      zones: [
        TechnologyZone(
          id: 'tz-plenary',
          name: 'Plenary & Keynotes',
          hallId: 'hall-convention',
          color: colorAiHpc,
        ),
        TechnologyZone(
          id: 'tz-conf-1',
          name: 'Conference Hall 1',
          hallId: 'hall-convention',
          color: colorQuantum,
        ),
        TechnologyZone(
          id: 'tz-conf-2',
          name: 'Conference Hall 2',
          hallId: 'hall-convention',
          color: colorSemiconductors,
        ),
        TechnologyZone(
          id: 'tz-conf-3',
          name: 'Conference Hall 3',
          hallId: 'hall-convention',
          color: colorCybersecurity,
        ),
      ],
      nearbyFacilities: ['VIP Lounge', 'Press Media Centre', 'Executive Restrooms', 'Convention Dining'],
      subtitle: 'Inaugural Addresses, Plenary Keynotes, Ministerial Summits & Global Panels',
      isConvention: true,
      accentColor: Color(0xFF00F2FE),
    ),
  ];

  /// Comprehensive Facilities & Amenities at Chennai Trade Centre
  static const List<FacilityItem> allFacilities = [
    FacilityItem(
      id: 'fac-entrance',
      name: 'Main Grand Entrance & Security Portico',
      type: FacilityType.mainEntrance,
      position: mainEntranceCoord,
      description: 'Primary security screening, metal detectors, and delegate arrival drop-off.',
    ),
    FacilityItem(
      id: 'fac-reg',
      name: 'Main Registration & Badge Collection',
      type: FacilityType.registrationDesk,
      position: registrationCoord,
      description: 'Express QR badge printing, VIP protocol counters, and attendee kit distribution.',
    ),
    FacilityItem(
      id: 'fac-info-main',
      name: 'Central Information & Help Desk',
      type: FacilityType.infoDesk,
      position: Offset(420, 1190),
      description: 'Event schedule assistance, language support, lost & found, and wheelchair access.',
    ),
    FacilityItem(
      id: 'fac-help-tech',
      name: 'Technical Support & App Help Desk',
      type: FacilityType.helpDesk,
      position: Offset(580, 1190),
      description: 'Mobile pass troubleshooting, Wi-Fi onboarding, and meeting lounge bookings.',
    ),
    FacilityItem(
      id: 'fac-food-south',
      name: 'South Food Court & Cafeteria',
      type: FacilityType.foodCourt,
      position: Offset(940, 850),
      description: 'South Indian cuisine, multi-cuisine deli, espresso bars, and shaded outdoor seating.',
    ),
    FacilityItem(
      id: 'fac-food-north',
      name: 'North Food Pavilion & Cafe',
      type: FacilityType.foodCourt,
      position: Offset(940, 390),
      description: 'Artisanal coffee, healthy bowls, quick snacks, and networking lounge tables.',
    ),
    FacilityItem(
      id: 'fac-restroom-1',
      name: 'Restrooms (Phase 1 Concourse)',
      type: FacilityType.restroom,
      position: Offset(500, 1140),
      description: 'Accessible male, female, and gender-neutral washrooms with diaper changing stations.',
    ),
    FacilityItem(
      id: 'fac-restroom-2',
      name: 'Restrooms (Central Concourse)',
      type: FacilityType.restroom,
      position: Offset(500, 710),
      description: 'Modern sanitation blocks equipped with eco-touchless sensors.',
    ),
    FacilityItem(
      id: 'fac-restroom-3',
      name: 'Restrooms (Convention Wing)',
      type: FacilityType.restroom,
      position: Offset(130, 140),
      description: 'Executive restrooms adjacent to Conference Hall 1.',
    ),
    FacilityItem(
      id: 'fac-aid-main',
      name: 'Central First Aid & Medical Hub',
      type: FacilityType.firstAid,
      position: Offset(60, 1190),
      description: '24/7 on-site doctor, paramedic staff, automated defibrillators (AED), and standby ambulance.',
    ),
    FacilityItem(
      id: 'fac-aid-north',
      name: 'North First Aid Station',
      type: FacilityType.firstAid,
      position: Offset(60, 420),
      description: 'Paramedic triage station with oxygen support and quick response aid kit.',
    ),
    FacilityItem(
      id: 'fac-exit-1',
      name: 'Emergency Exit 1 (South West)',
      type: FacilityType.emergencyExit,
      position: Offset(40, 1060),
      description: 'Emergency egress route leading directly to Open Assembly Area A.',
    ),
    FacilityItem(
      id: 'fac-exit-2',
      name: 'Emergency Exit 2 (South East)',
      type: FacilityType.emergencyExit,
      position: Offset(960, 1060),
      description: 'Emergency egress leading to Open Assembly Area B.',
    ),
    FacilityItem(
      id: 'fac-exit-3',
      name: 'Emergency Exit 3 (North West)',
      type: FacilityType.emergencyExit,
      position: Offset(40, 360),
      description: 'Emergency egress leading to Open Assembly Area C.',
    ),
    FacilityItem(
      id: 'fac-exit-4',
      name: 'Emergency Exit 4 (North East)',
      type: FacilityType.emergencyExit,
      position: Offset(960, 360),
      description: 'Emergency egress leading to Open Assembly Area D.',
    ),
    FacilityItem(
      id: 'fac-parking-a',
      name: 'Delegate Parking Zone A',
      type: FacilityType.parkingArea,
      position: Offset(260, 1370),
      description: 'Multi-level car parking with 1,200 bay capacity and EV fast charging hubs.',
    ),
    FacilityItem(
      id: 'fac-parking-b',
      name: 'VIP & Speaker Parking Zone B',
      type: FacilityType.parkingArea,
      position: Offset(740, 1370),
      description: 'Chauffeur lounge and designated reserved parking for diplomats and keynote speakers.',
    ),
  ];

  /// Venue Master Object
  static Venue getVenue() {
    return const Venue(
      id: 'ctc-chennai',
      name: 'Nandambakkam, Tamil Nadu 600089',
      address: 'Nandambakkam, Tamil Nadu',
      city: 'Tamil Nadu',
      postalCode: '600089',
      halls: allHalls,
      facilities: allFacilities,
      officialFloorPlanUrl: officialFloorPlanUrl,
      officialFloorPlanAsset: officialFloorPlanAsset,
    );
  }

  /// Calculates a realistic step-by-step route from the Main Entrance to any Hall
  static NavigationRoute calculateRouteTo({
    required String targetHallId,
    String? destinationTitle,
    Offset? targetCoordinates,
  }) {
    final hall = allHalls.firstWhere(
      (h) => h.id == targetHallId,
      orElse: () => allHalls.first,
    );

    final dest = targetCoordinates ?? hall.center;
    final List<Offset> waypoints = [];
    final List<String> steps = [];

    // Starting Point
    waypoints.add(mainEntranceCoord);
    steps.add('Start at the Main Grand Entrance & Security Screening');

    // Registration Concourse
    waypoints.add(registrationCoord);
    steps.add('Proceed through the Main Registration Concourse');

    // Waypoint Routing through Central Spine Waypoint Network
    if (hall.id == 'hall-1') {
      waypoints.add(const Offset(500, 1060));
      waypoints.add(dest);
      steps.add('Turn left into Hall 1 Entrance (West Promenade)');
      steps.add('Arrive at ${destinationTitle ?? hall.name}');
    } else if (hall.id == 'hall-2') {
      waypoints.add(const Offset(500, 1060));
      waypoints.add(dest);
      steps.add('Turn right into Hall 2 Entrance (East Promenade)');
      steps.add('Arrive at ${destinationTitle ?? hall.name}');
    } else if (hall.id == 'hall-3') {
      waypoints.add(const Offset(500, 1060));
      waypoints.add(const Offset(500, 825));
      waypoints.add(dest);
      steps.add('Continue straight along Central Neon Concourse past Hall 1');
      steps.add('Turn left into Hall 3 Entrance');
      steps.add('Arrive at ${destinationTitle ?? hall.name}');
    } else if (hall.id == 'hall-4') {
      waypoints.add(const Offset(500, 1060));
      waypoints.add(const Offset(500, 825));
      waypoints.add(dest);
      steps.add('Continue straight along Central Neon Concourse past Hall 2');
      steps.add('Turn right into Hall 4 Entrance');
      steps.add('Arrive at ${destinationTitle ?? hall.name}');
    } else if (hall.id == 'hall-5') {
      waypoints.add(const Offset(500, 920));
      waypoints.add(const Offset(500, 595));
      waypoints.add(dest);
      steps.add('Walk through Phase 1-2 Glass Covered Skyway to Upper Complex');
      steps.add('Turn left into Hall 5 (Defence & Aerospace)');
      steps.add('Arrive at ${destinationTitle ?? hall.name}');
    } else if (hall.id == 'hall-6') {
      waypoints.add(const Offset(500, 920));
      waypoints.add(const Offset(500, 595));
      waypoints.add(dest);
      steps.add('Walk through Phase 1-2 Glass Covered Skyway to Upper Complex');
      steps.add('Turn right into Hall 6 (MedTech & Bio-Informatics)');
      steps.add('Arrive at ${destinationTitle ?? hall.name}');
    } else if (hall.id == 'hall-7') {
      waypoints.add(const Offset(500, 920));
      waypoints.add(const Offset(500, 365));
      waypoints.add(dest);
      steps.add('Proceed north along the Grand Promenade towards Hall 7');
      steps.add('Turn left into Hall 7 (Smart Mobility & EV)');
      steps.add('Arrive at ${destinationTitle ?? hall.name}');
    } else if (hall.id == 'hall-8') {
      waypoints.add(const Offset(500, 920));
      waypoints.add(const Offset(500, 365));
      waypoints.add(dest);
      steps.add('Proceed north along the Grand Promenade towards Hall 8');
      steps.add('Turn right into Hall 8 (Startup Arena)');
      steps.add('Arrive at ${destinationTitle ?? hall.name}');
    } else {
      // Convention Centre
      waypoints.add(const Offset(500, 920));
      waypoints.add(const Offset(500, 480));
      waypoints.add(const Offset(500, 240));
      waypoints.add(dest);
      steps.add('Follow the VIP Wayfinding Path all the way north to Convention Plaza');
      steps.add('Ascend escalators to Grand Convention Centre & Conference Halls');
      steps.add('Arrive at Grand Convention Centre');
    }

    // Estimate realistic physical distance: 1 canvas unit approx 0.35 meters
    double totalDistUnits = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDistUnits += (waypoints[i + 1] - waypoints[i]).distance;
    }
    final distanceMeters = (totalDistUnits * 0.35).roundToDouble();
    final estimatedMinutes = (distanceMeters / 60.0).ceil().clamp(1, 10);

    return NavigationRoute(
      destinationName: destinationTitle ?? hall.name,
      destinationHall: hall.name,
      waypoints: waypoints,
      distanceMeters: distanceMeters,
      estimatedWalkingMinutes: estimatedMinutes,
      steps: steps,
    );
  }
}
