class JourneyStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final int walkMinutes;

  const JourneyStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distanceMeters = 0.0,
    this.walkMinutes = 0,
  });

  factory JourneyStop.fromJson(Map<String, dynamic> json) {
    return JourneyStop(
      id: json['id'] as String? ?? json['stopId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ??
          ((json['distanceKm'] as num?)?.toDouble() ?? 0.0) * 1000,
      walkMinutes: (json['walkMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'distanceMeters': distanceMeters,
        'walkMinutes': walkMinutes,
      };
}

class JourneyBusOption {
  final String busId;
  final String busNumber;
  final String routeId;
  final String routeName;
  final String origin;
  final String destination;
  final bool isLive;
  final String statusLabel; // 'LIVE NOW' or 'UPCOMING'
  final String? currentLocation;
  final String? nextStop;
  final int etaMinutes;
  final String journeyDuration;
  final double walkingDistanceMeters;
  final int walkingMinutes;
  final String boardingStopName;
  final String destinationStopName;
  final bool isDirect;
  final int transfers;
  final List<JourneyLeg> legs;

  const JourneyBusOption({
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.routeName,
    required this.origin,
    required this.destination,
    this.isLive = false,
    required this.statusLabel,
    this.currentLocation,
    this.nextStop,
    required this.etaMinutes,
    required this.journeyDuration,
    this.walkingDistanceMeters = 0.0,
    this.walkingMinutes = 0,
    required this.boardingStopName,
    required this.destinationStopName,
    this.isDirect = true,
    this.transfers = 0,
    this.legs = const [],
  });

  factory JourneyBusOption.fromJson(Map<String, dynamic> json) {
    return JourneyBusOption(
      busId: json['busId'] as String? ?? '',
      busNumber: json['busNumber'] as String? ?? '',
      routeId: json['routeId'] as String? ?? '',
      routeName: json['routeName'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      isLive: json['isLive'] as bool? ?? false,
      statusLabel: json['statusLabel'] as String? ??
          ((json['isLive'] == true) ? 'LIVE NOW' : 'UPCOMING'),
      currentLocation: json['currentLocation'] as String?,
      nextStop: json['nextStop'] as String?,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 10,
      journeyDuration: json['journeyDuration'] as String? ?? '45 min',
      walkingDistanceMeters:
          (json['walkingDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      walkingMinutes: (json['walkingMinutes'] as num?)?.toInt() ?? 0,
      boardingStopName: json['boardingStopName'] as String? ?? '',
      destinationStopName: json['destinationStopName'] as String? ?? '',
      isDirect: json['isDirect'] as bool? ?? true,
      transfers: (json['transfers'] as num?)?.toInt() ?? 0,
      legs: (json['legs'] as List<dynamic>?)
              ?.map((e) => JourneyLeg.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'busId': busId,
        'busNumber': busNumber,
        'routeId': routeId,
        'routeName': routeName,
        'origin': origin,
        'destination': destination,
        'isLive': isLive,
        'statusLabel': statusLabel,
        'currentLocation': currentLocation,
        'nextStop': nextStop,
        'etaMinutes': etaMinutes,
        'journeyDuration': journeyDuration,
        'walkingDistanceMeters': walkingDistanceMeters,
        'walkingMinutes': walkingMinutes,
        'boardingStopName': boardingStopName,
        'destinationStopName': destinationStopName,
        'isDirect': isDirect,
        'transfers': transfers,
        'legs': legs.map((l) => l.toJson()).toList(),
      };
}

class JourneyLeg {
  final String type; // 'WALK', 'BUS'
  final String title;
  final String instruction;
  final int durationMinutes;
  final String? busNumber;
  final String? fromStop;
  final String? toStop;

  const JourneyLeg({
    required this.type,
    required this.title,
    required this.instruction,
    required this.durationMinutes,
    this.busNumber,
    this.fromStop,
    this.toStop,
  });

  factory JourneyLeg.fromJson(Map<String, dynamic> json) {
    return JourneyLeg(
      type: json['type'] as String? ?? 'BUS',
      title: json['title'] as String? ?? '',
      instruction: json['instruction'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      busNumber: json['busNumber'] as String?,
      fromStop: json['fromStop'] as String?,
      toStop: json['toStop'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'instruction': instruction,
        'durationMinutes': durationMinutes,
        if (busNumber != null) 'busNumber': busNumber,
        if (fromStop != null) 'fromStop': fromStop,
        if (toStop != null) 'toStop': toStop,
      };
}

class JourneySearchResult {
  final String fromQuery;
  final String toQuery;
  final JourneyStop recommendedBoardingStop;
  final List<JourneyStop> alternativeBoardingStops;
  final JourneyStop destinationStop;
  final List<JourneyBusOption> directRoutes;
  final List<JourneyBusOption> connectingRoutes;
  final List<JourneyBusOption> allOptions;

  const JourneySearchResult({
    required this.fromQuery,
    required this.toQuery,
    required this.recommendedBoardingStop,
    this.alternativeBoardingStops = const [],
    required this.destinationStop,
    required this.directRoutes,
    this.connectingRoutes = const [],
    required this.allOptions,
  });

  factory JourneySearchResult.fromJson(Map<String, dynamic> json) {
    final direct = (json['directRoutes'] as List<dynamic>?)
            ?.map((e) => JourneyBusOption.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final connecting = (json['connectingRoutes'] as List<dynamic>?)
            ?.map((e) => JourneyBusOption.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return JourneySearchResult(
      fromQuery: json['fromQuery'] as String? ?? '',
      toQuery: json['toQuery'] as String? ?? '',
      recommendedBoardingStop: JourneyStop.fromJson(
          json['recommendedBoardingStop'] as Map<String, dynamic>? ?? {}),
      alternativeBoardingStops: (json['alternativeBoardingStops']
                  as List<dynamic>?)
              ?.map((e) => JourneyStop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      destinationStop: JourneyStop.fromJson(
          json['destinationStop'] as Map<String, dynamic>? ?? {}),
      directRoutes: direct,
      connectingRoutes: connecting,
      allOptions: [...direct, ...connecting],
    );
  }
}
