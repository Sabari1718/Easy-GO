import 'package:flutter/material.dart';

enum BusJourneyStatus {
  notStarted,
  moving,
  approachingStop,
  stoppedAtStop,
  serviceEnded,
}

extension BusJourneyStatusX on BusJourneyStatus {
  String get label {
    switch (this) {
      case BusJourneyStatus.notStarted:
        return 'Not Started';
      case BusJourneyStatus.moving:
        return 'Moving';
      case BusJourneyStatus.approachingStop:
        return 'Approaching Stop';
      case BusJourneyStatus.stoppedAtStop:
        return 'Stopped at Stop';
      case BusJourneyStatus.serviceEnded:
        return 'Service Ended';
    }
  }

  String get emoji {
    switch (this) {
      case BusJourneyStatus.notStarted:
        return '⚪';
      case BusJourneyStatus.moving:
        return '🟢';
      case BusJourneyStatus.approachingStop:
        return '🔵';
      case BusJourneyStatus.stoppedAtStop:
        return '🟡';
      case BusJourneyStatus.serviceEnded:
        return '🔴';
    }
  }

  Color get color {
    switch (this) {
      case BusJourneyStatus.notStarted:
        return const Color(0xFF94A3B8);
      case BusJourneyStatus.moving:
        return const Color(0xFF22C55E);
      case BusJourneyStatus.approachingStop:
        return const Color(0xFF3B82F6);
      case BusJourneyStatus.stoppedAtStop:
        return const Color(0xFFF59E0B);
      case BusJourneyStatus.serviceEnded:
        return const Color(0xFFEF4444);
    }
  }
}

class BusLiveState {
  final String busId;
  final String busNumber;
  final String routeId;
  final String routeName;
  final double latitude;
  final double longitude;
  final double speed; // km/h
  final double heading; // degrees (0-360)
  final String currentStopId;
  final String currentStopName;
  final int currentStopIndex;
  final String nextStopId;
  final String nextStopName;
  final int nextStopIndex;
  final double distanceToNextStop; // km
  final double distanceTravelled; // km
  final double distanceRemaining; // km
  final double totalRouteDistance; // km
  final int etaMinutes;
  final double progressPercentage; // 0.0 to 100.0
  final BusJourneyStatus status;
  final String statusMessage;
  final DateTime lastUpdated;
  final String locationStatus; // LIVE, RECENT, STALE, OFFLINE
  final int secondsSinceUpdate;
  final bool trackerOnline;
  final String? selectedStopId;
  final String? selectedStopName;
  final double? distanceToSelectedStop;
  final int? etaToSelectedStop;
  final int? stopsToSelectedStop;
  final bool isPaused;
  final double speedMultiplier;
  final int currentRoutePointIndex;
  final int dwellTimeRemainingSeconds;

  const BusLiveState({
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.currentStopId,
    required this.currentStopName,
    required this.currentStopIndex,
    required this.nextStopId,
    required this.nextStopName,
    required this.nextStopIndex,
    required this.distanceToNextStop,
    required this.distanceTravelled,
    required this.distanceRemaining,
    required this.totalRouteDistance,
    required this.etaMinutes,
    required this.progressPercentage,
    required this.status,
    required this.statusMessage,
    required this.lastUpdated,
    this.locationStatus = 'LIVE',
    this.secondsSinceUpdate = 0,
    this.trackerOnline = true,
    this.selectedStopId,
    this.selectedStopName,
    this.distanceToSelectedStop,
    this.etaToSelectedStop,
    this.stopsToSelectedStop,
    this.isPaused = false,
    this.speedMultiplier = 1.0,
    this.currentRoutePointIndex = 0,
    this.dwellTimeRemainingSeconds = 0,
  });

  bool get isLiveLocation => locationStatus == 'LIVE' && secondsSinceUpdate <= 15;
  bool get isRecentLocation => locationStatus == 'RECENT' || (secondsSinceUpdate > 15 && secondsSinceUpdate <= 60);
  bool get isStaleLocation => locationStatus == 'STALE' || (secondsSinceUpdate > 60 && secondsSinceUpdate <= 300);
  bool get isOfflineLocation => locationStatus == 'OFFLINE' || secondsSinceUpdate > 300;

  String get freshnessLabel {
    if (isLiveLocation) {
      return 'LIVE • Updated ${secondsSinceUpdate <= 1 ? "just now" : "$secondsSinceUpdate sec ago"}';
    }
    if (isRecentLocation) {
      return 'RECENT • Updated $secondsSinceUpdate sec ago';
    }
    if (isStaleLocation) {
      final mins = (secondsSinceUpdate / 60).round();
      return 'STALE • Updated ${mins <= 1 ? "1 min" : "$mins min"} ago';
    }
    return 'LOCATION UNAVAILABLE';
  }

  Color get statusBadgeColor {
    if (isLiveLocation) return const Color(0xFF22C55E);
    if (isRecentLocation) return const Color(0xFFEAB308);
    if (isStaleLocation) return const Color(0xFFF97316);
    return const Color(0xFF64748B);
  }

  BusLiveState copyWith({
    String? busId,
    String? busNumber,
    String? routeId,
    String? routeName,
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    String? currentStopId,
    String? currentStopName,
    int? currentStopIndex,
    String? nextStopId,
    String? nextStopName,
    int? nextStopIndex,
    double? distanceToNextStop,
    double? distanceTravelled,
    double? distanceRemaining,
    double? totalRouteDistance,
    int? etaMinutes,
    double? progressPercentage,
    BusJourneyStatus? status,
    String? statusMessage,
    DateTime? lastUpdated,
    String? selectedStopId,
    String? selectedStopName,
    double? distanceToSelectedStop,
    int? etaToSelectedStop,
    int? stopsToSelectedStop,
    bool? isPaused,
    double? speedMultiplier,
    int? currentRoutePointIndex,
    int? dwellTimeRemainingSeconds,
  }) {
    return BusLiveState(
      busId: busId ?? this.busId,
      busNumber: busNumber ?? this.busNumber,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      currentStopId: currentStopId ?? this.currentStopId,
      currentStopName: currentStopName ?? this.currentStopName,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      nextStopId: nextStopId ?? this.nextStopId,
      nextStopName: nextStopName ?? this.nextStopName,
      nextStopIndex: nextStopIndex ?? this.nextStopIndex,
      distanceToNextStop: distanceToNextStop ?? this.distanceToNextStop,
      distanceTravelled: distanceTravelled ?? this.distanceTravelled,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      totalRouteDistance: totalRouteDistance ?? this.totalRouteDistance,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      selectedStopId: selectedStopId ?? this.selectedStopId,
      selectedStopName: selectedStopName ?? this.selectedStopName,
      distanceToSelectedStop:
          distanceToSelectedStop ?? this.distanceToSelectedStop,
      etaToSelectedStop: etaToSelectedStop ?? this.etaToSelectedStop,
      stopsToSelectedStop: stopsToSelectedStop ?? this.stopsToSelectedStop,
      isPaused: isPaused ?? this.isPaused,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      currentRoutePointIndex:
          currentRoutePointIndex ?? this.currentRoutePointIndex,
      dwellTimeRemainingSeconds:
          dwellTimeRemainingSeconds ?? this.dwellTimeRemainingSeconds,
    );
  }

  factory BusLiveState.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'MOVING').toUpperCase();
    BusJourneyStatus busStatus;
    if (statusStr.contains('STOPPED')) {
      busStatus = BusJourneyStatus.stoppedAtStop;
    } else if (statusStr.contains('APPROACH')) {
      busStatus = BusJourneyStatus.approachingStop;
    } else if (statusStr.contains('COMPLETE')) {
      busStatus = BusJourneyStatus.serviceEnded;
    } else if (statusStr.contains('NOT_STARTED')) {
      busStatus = BusJourneyStatus.notStarted;
    } else {
      busStatus = BusJourneyStatus.moving;
    }

    final curStop = json['currentStop'] as String? ??
        json['currentStopName'] as String? ??
        'Current Stop';
    final nxtStop = json['nextStop'] as String? ??
        json['nextStopName'] as String? ??
        'Next Stop';

    return BusLiveState(
      busId: json['busId'] as String? ?? '',
      busNumber: json['busNumber'] as String? ?? '12A',
      routeId: json['routeId'] as String? ?? '',
      routeName: json['routeName'] as String? ??
          (json['route'] is Map ? (json['route']['name'] as String? ?? '') : ''),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.9601,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 76.9502,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      currentStopId: json['currentStopId'] as String? ?? '',
      currentStopName: curStop,
      currentStopIndex: (json['currentStopIndex'] as num?)?.toInt() ?? 0,
      nextStopId: json['nextStopId'] as String? ?? '',
      nextStopName: nxtStop,
      nextStopIndex: (json['nextStopIndex'] as num?)?.toInt() ?? 1,
      distanceToNextStop: (json['distanceToNextStop'] as num?)?.toDouble() ?? 0.0,
      distanceTravelled: (json['distanceTravelled'] as num?)?.toDouble() ??
          (json['distanceTravelledKm'] as num?)?.toDouble() ?? 0.0,
      distanceRemaining: (json['distanceRemaining'] as num?)?.toDouble() ??
          (json['distanceRemainingKm'] as num?)?.toDouble() ?? 0.0,
      totalRouteDistance: (json['totalRouteDistance'] as num?)?.toDouble() ??
          (json['totalRouteDistanceKm'] as num?)?.toDouble() ?? 42.5,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 8,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      status: busStatus,
      statusMessage: busStatus == BusJourneyStatus.stoppedAtStop
          ? 'Bus stopped at $curStop'
          : (busStatus == BusJourneyStatus.approachingStop
              ? 'Approaching $nxtStop'
              : 'Left $curStop • Moving to $nxtStop'),
      lastUpdated: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now())
          : (json['lastUpdated'] != null
              ? (DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now())
              : (json['lastUpdatedAt'] != null
                  ? (DateTime.tryParse(json['lastUpdatedAt'] as String) ?? DateTime.now())
                  : DateTime.now())),
      locationStatus: (json['locationStatus'] as String?)?.toUpperCase() ??
          (((json['secondsSinceUpdate'] as num?)?.toInt() ?? 0) <= 15
              ? 'LIVE'
              : (((json['secondsSinceUpdate'] as num?)?.toInt() ?? 0) <= 60
                  ? 'RECENT'
                  : (((json['secondsSinceUpdate'] as num?)?.toInt() ?? 0) <= 300 ? 'STALE' : 'OFFLINE'))),
      secondsSinceUpdate: (json['secondsSinceUpdate'] as num?)?.toInt() ?? 0,
      trackerOnline: json['trackerOnline'] as bool? ?? true,
      currentRoutePointIndex: (json['currentRoutePointIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
