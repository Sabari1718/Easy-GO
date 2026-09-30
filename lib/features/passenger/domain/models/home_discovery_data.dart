import 'bus_stop_info.dart';

class NearbyBusItem {
  final String busId;
  final String busNumber;
  final String routeId;
  final String routeName;
  final String origin;
  final String destination;
  final double distanceKm;
  final int etaMinutes;
  final bool isLive;
  final String status;
  final String currentStop;
  final String nextStop;
  final double speed;

  const NearbyBusItem({
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.etaMinutes,
    required this.isLive,
    required this.status,
    required this.currentStop,
    required this.nextStop,
    this.speed = 0.0,
  });

  factory NearbyBusItem.fromJson(Map<String, dynamic> json) {
    return NearbyBusItem(
      busId: json['busId'] as String? ?? '',
      busNumber: json['busNumber'] as String? ?? '',
      routeId: json['routeId'] as String? ?? '',
      routeName: json['routeName'] as String? ?? json['route'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 5,
      isLive: json['isLive'] as bool? ?? (json['status'] != 'OFFLINE'),
      status: json['status'] as String? ?? 'ACTIVE',
      currentStop: json['currentStop'] as String? ?? '',
      nextStop: json['nextStop'] as String? ?? '',
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'busId': busId,
        'busNumber': busNumber,
        'routeId': routeId,
        'routeName': routeName,
        'origin': origin,
        'destination': destination,
        'distanceKm': distanceKm,
        'etaMinutes': etaMinutes,
        'isLive': isLive,
        'status': status,
        'currentStop': currentStop,
        'nextStop': nextStop,
        'speed': speed,
      };
}

class NearbyRouteItem {
  final String routeId;
  final String routeNumber;
  final String routeName;
  final String source;
  final String destination;
  final int activeBusCount;

  const NearbyRouteItem({
    required this.routeId,
    required this.routeNumber,
    required this.routeName,
    required this.source,
    required this.destination,
    this.activeBusCount = 0,
  });

  factory NearbyRouteItem.fromJson(Map<String, dynamic> json) {
    return NearbyRouteItem(
      routeId: json['routeId'] as String? ?? json['id'] as String? ?? '',
      routeNumber: json['routeNumber'] as String? ?? json['name'] as String? ?? '',
      routeName: json['routeName'] as String? ?? json['name'] as String? ?? '',
      source: json['source'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      activeBusCount: (json['activeBusCount'] as num?)?.toInt() ??
          (json['busCount'] as num?)?.toInt() ??
          0,
    );
  }
}

class HomeDiscoveryData {
  final String locationSummary;
  final double latitude;
  final double longitude;
  final List<NearbyBusItem> nearbyBuses;
  final List<BusStopInfo> nearbyStops;
  final List<NearbyRouteItem> nearbyRoutes;

  const HomeDiscoveryData({
    required this.locationSummary,
    required this.latitude,
    required this.longitude,
    required this.nearbyBuses,
    required this.nearbyStops,
    required this.nearbyRoutes,
  });
}
