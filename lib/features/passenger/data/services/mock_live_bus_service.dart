import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Live Bus Status ────────────────────────────────────────────────────────

enum LiveBusStatus { onTime, delayed, approaching, notRunning }

extension LiveBusStatusExtension on LiveBusStatus {
  String get label {
    switch (this) {
      case LiveBusStatus.onTime:
        return 'On Time';
      case LiveBusStatus.delayed:
        return 'Delayed';
      case LiveBusStatus.approaching:
        return 'Approaching';
      case LiveBusStatus.notRunning:
        return 'Not Running';
    }
  }
}

// ─── Live Bus Location ───────────────────────────────────────────────────────

class LiveBusLocation {
  final String busId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speedKmh;
  final int etaMinutes;
  final int stopsAway;
  final String currentStop;
  final String nextStop;
  final String destination;
  final LiveBusStatus status;
  final DateTime updatedAt;
  final double distanceKm; // from user

  const LiveBusLocation({
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speedKmh,
    required this.etaMinutes,
    required this.stopsAway,
    required this.currentStop,
    required this.nextStop,
    required this.destination,
    required this.status,
    required this.updatedAt,
    this.distanceKm = 0.0,
  });

  LiveBusLocation copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? speedKmh,
    int? etaMinutes,
    int? stopsAway,
    String? currentStop,
    String? nextStop,
    LiveBusStatus? status,
    DateTime? updatedAt,
    double? distanceKm,
  }) {
    return LiveBusLocation(
      busId: busId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speedKmh: speedKmh ?? this.speedKmh,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      stopsAway: stopsAway ?? this.stopsAway,
      currentStop: currentStop ?? this.currentStop,
      nextStop: nextStop ?? this.nextStop,
      destination: destination,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

// ─── Rich Bus Info Card (static metadata) ────────────────────────────────────

class LiveBusInfo {
  final String busId;
  final String busNumber;
  final String origin;
  final String destination;
  final String routeId;
  final List<RouteStop> allStops;
  final List<LatLngPoint> routePolyline;
  final bool isFavorite;

  const LiveBusInfo({
    required this.busId,
    required this.busNumber,
    required this.origin,
    required this.destination,
    required this.routeId,
    required this.allStops,
    required this.routePolyline,
    this.isFavorite = false,
  });

  LiveBusInfo copyWith({bool? isFavorite}) {
    return LiveBusInfo(
      busId: busId,
      busNumber: busNumber,
      origin: origin,
      destination: destination,
      routeId: routeId,
      allStops: allStops,
      routePolyline: routePolyline,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class RouteStop {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const RouteStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class LatLngPoint {
  final double lat;
  final double lng;
  const LatLngPoint(this.lat, this.lng);
}

// ─── Mock Data ───────────────────────────────────────────────────────────────

// Coimbatore area routes (real coords near Gandhipuram)
final _allBuses = <LiveBusInfo>[
  LiveBusInfo(
    busId: 'bus_12a',
    busNumber: '12A',
    origin: 'Ukkadam',
    destination: 'Pollachi',
    routeId: 'r12a_ukkadam_pollachi',
    allStops: [
      const RouteStop(id: 's1', name: 'Ukkadam', lat: 10.9902, lng: 76.9607),
      const RouteStop(id: 's2', name: 'Sundakkamuthur', lat: 10.9572, lng: 76.9485),
      const RouteStop(id: 's3', name: 'Madukkarai', lat: 10.9038, lng: 76.9602),
      const RouteStop(id: 's4', name: 'Ettimadai', lat: 10.8986, lng: 76.9030),
      const RouteStop(id: 's5', name: 'Karpagam', lat: 10.9022, lng: 76.9744),
      const RouteStop(id: 's6', name: 'Kinathukadavu', lat: 10.8174, lng: 77.0194),
      const RouteStop(id: 's7', name: 'Eachanari', lat: 10.9328, lng: 76.9701),
      const RouteStop(id: 's8', name: 'Pollachi', lat: 10.6588, lng: 77.0090),
    ],
    routePolyline: [
      // 1. Ukkadam
      LatLngPoint(10.9902, 76.9607),
      LatLngPoint(10.9875, 76.9598),
      LatLngPoint(10.9840, 76.9582),
      LatLngPoint(10.9805, 76.9568),
      LatLngPoint(10.9770, 76.9552),
      LatLngPoint(10.9730, 76.9535),
      LatLngPoint(10.9690, 76.9520),
      LatLngPoint(10.9645, 76.9505),
      LatLngPoint(10.9610, 76.9495),
      // 2. Sundakkamuthur
      LatLngPoint(10.9572, 76.9485),
      LatLngPoint(10.9520, 76.9490),
      LatLngPoint(10.9470, 76.9502),
      LatLngPoint(10.9415, 76.9520),
      LatLngPoint(10.9360, 76.9538),
      LatLngPoint(10.9300, 76.9555),
      LatLngPoint(10.9235, 76.9572),
      LatLngPoint(10.9170, 76.9588),
      LatLngPoint(10.9100, 76.9598),
      // 3. Madukkarai
      LatLngPoint(10.9038, 76.9602),
      LatLngPoint(10.9035, 76.9540),
      LatLngPoint(10.9030, 76.9470),
      LatLngPoint(10.9025, 76.9400),
      LatLngPoint(10.9018, 76.9320),
      LatLngPoint(10.9010, 76.9240),
      LatLngPoint(10.9002, 76.9160),
      LatLngPoint(10.8994, 76.9090),
      // 4. Ettimadai
      LatLngPoint(10.8986, 76.9030),
      LatLngPoint(10.8992, 76.9110),
      LatLngPoint(10.9000, 76.9200),
      LatLngPoint(10.9010, 76.9310),
      LatLngPoint(10.9020, 76.9430),
      LatLngPoint(10.9030, 76.9540),
      LatLngPoint(10.9035, 76.9630),
      LatLngPoint(10.9030, 76.9690),
      // 5. Karpagam
      LatLngPoint(10.9022, 76.9744),
      LatLngPoint(10.8960, 76.9780),
      LatLngPoint(10.8890, 76.9825),
      LatLngPoint(10.8810, 76.9875),
      LatLngPoint(10.8730, 76.9925),
      LatLngPoint(10.8640, 76.9975),
      LatLngPoint(10.8540, 77.0030),
      LatLngPoint(10.8440, 77.0080),
      LatLngPoint(10.8340, 77.0125),
      LatLngPoint(10.8250, 77.0165),
      // 6. Kinathukadavu
      LatLngPoint(10.8174, 77.0194),
      LatLngPoint(10.8260, 77.0160),
      LatLngPoint(10.8370, 77.0110),
      LatLngPoint(10.8490, 77.0050),
      LatLngPoint(10.8620, 76.9980),
      LatLngPoint(10.8760, 76.9910),
      LatLngPoint(10.8900, 76.9840),
      LatLngPoint(10.9040, 76.9790),
      LatLngPoint(10.9180, 76.9750),
      // 7. Eachanari
      LatLngPoint(10.9328, 76.9701),
      LatLngPoint(10.9200, 76.9740),
      LatLngPoint(10.9050, 76.9785),
      LatLngPoint(10.8880, 76.9840),
      LatLngPoint(10.8700, 76.9910),
      LatLngPoint(10.8500, 76.9990),
      LatLngPoint(10.8300, 77.0110),
      LatLngPoint(10.8100, 77.0190),
      LatLngPoint(10.7850, 77.0220),
      LatLngPoint(10.7600, 77.0210),
      LatLngPoint(10.7350, 77.0195),
      LatLngPoint(10.7100, 77.0175),
      LatLngPoint(10.6850, 77.0140),
      LatLngPoint(10.6700, 77.0115),
      // 8. Pollachi
      LatLngPoint(10.6588, 77.0090),
    ],
  ),
  LiveBusInfo(
    busId: 'bus_24',
    busNumber: '24',
    origin: 'Gandhipuram',
    destination: 'Singanallur',
    routeId: 'r24',
    allStops: [
      const RouteStop(id: 's1', name: 'Gandhipuram', lat: 11.0168, lng: 76.9558),
      const RouteStop(id: 's2', name: 'Race Course', lat: 11.0200, lng: 76.9650),
      const RouteStop(id: 's3', name: 'Saibaba Colony', lat: 11.0180, lng: 76.9750),
      const RouteStop(id: 's4', name: 'Ramanathapuram', lat: 11.0100, lng: 76.9900),
      const RouteStop(id: 's5', name: 'Singanallur', lat: 11.0020, lng: 77.0000),
    ],
    routePolyline: [
      LatLngPoint(11.0168, 76.9558),
      LatLngPoint(11.0180, 76.9600),
      LatLngPoint(11.0200, 76.9650),
      LatLngPoint(11.0190, 76.9700),
      LatLngPoint(11.0180, 76.9750),
      LatLngPoint(11.0150, 76.9820),
      LatLngPoint(11.0100, 76.9900),
      LatLngPoint(11.0060, 76.9950),
      LatLngPoint(11.0020, 77.0000),
    ],
  ),
  LiveBusInfo(
    busId: 'bus_5b',
    busNumber: '5B',
    origin: 'RS Puram',
    destination: 'Kovaipudur',
    routeId: 'r5b',
    allStops: [
      const RouteStop(id: 's1', name: 'RS Puram', lat: 11.0080, lng: 76.9480),
      const RouteStop(id: 's2', name: 'Gandhipuram', lat: 11.0168, lng: 76.9558),
      const RouteStop(id: 's3', name: 'Peelamedu', lat: 11.0000, lng: 76.9780),
      const RouteStop(id: 's4', name: 'Avinashi Road', lat: 10.9950, lng: 76.9900),
      const RouteStop(id: 's5', name: 'Kovaipudur', lat: 10.9850, lng: 77.0000),
    ],
    routePolyline: [
      LatLngPoint(11.0080, 76.9480),
      LatLngPoint(11.0120, 76.9510),
      LatLngPoint(11.0168, 76.9558),
      LatLngPoint(11.0080, 76.9650),
      LatLngPoint(11.0000, 76.9780),
      LatLngPoint(10.9950, 76.9900),
      LatLngPoint(10.9850, 77.0000),
    ],
  ),
  LiveBusInfo(
    busId: 'bus_88',
    busNumber: '88',
    origin: 'Vadavalli',
    destination: 'Tiruppur',
    routeId: 'r88',
    allStops: [
      const RouteStop(id: 's1', name: 'Vadavalli', lat: 11.0350, lng: 76.9180),
      const RouteStop(id: 's2', name: 'Maruthamalai', lat: 11.0400, lng: 76.9300),
      const RouteStop(id: 's3', name: 'Gandhipuram', lat: 11.0168, lng: 76.9558),
      const RouteStop(id: 's4', name: 'Ganapathy', lat: 11.0250, lng: 76.9650),
      const RouteStop(id: 's5', name: 'Tiruppur', lat: 11.1000, lng: 77.3400),
    ],
    routePolyline: [
      LatLngPoint(11.0350, 76.9180),
      LatLngPoint(11.0380, 76.9240),
      LatLngPoint(11.0400, 76.9300),
      LatLngPoint(11.0300, 76.9420),
      LatLngPoint(11.0168, 76.9558),
      LatLngPoint(11.0220, 76.9600),
      LatLngPoint(11.0250, 76.9650),
    ],
  ),
  LiveBusInfo(
    busId: 'bus_20c',
    busNumber: '20C',
    origin: 'Mettupalayam',
    destination: 'Coimbatore',
    routeId: 'r20c',
    allStops: [
      const RouteStop(id: 's1', name: 'Mettupalayam', lat: 11.2980, lng: 76.9450),
      const RouteStop(id: 's2', name: 'Karamadai', lat: 11.2400, lng: 76.9600),
      const RouteStop(id: 's3', name: 'Periyanaickenpalayam', lat: 11.1500, lng: 76.9550),
      const RouteStop(id: 's4', name: 'Thudiyalur', lat: 11.0800, lng: 76.9500),
      const RouteStop(id: 's5', name: 'Gandhipuram', lat: 11.0168, lng: 76.9558),
    ],
    routePolyline: [
      LatLngPoint(11.2980, 76.9450),
      LatLngPoint(11.2700, 76.9520),
      LatLngPoint(11.2400, 76.9600),
      LatLngPoint(11.2000, 76.9580),
      LatLngPoint(11.1500, 76.9550),
      LatLngPoint(11.1100, 76.9530),
      LatLngPoint(11.0800, 76.9500),
      LatLngPoint(11.0500, 76.9520),
      LatLngPoint(11.0168, 76.9558),
    ],
  ),
];

// ─── Service ──────────────────────────────────────────────────────────────────

class MockLiveBusService {
  final Map<String, StreamController<LiveBusLocation>> _controllers = {};
  final Map<String, Timer> _timers = {};
  final Map<String, int> _routeIndices = {}; // current polyline index per bus
  final Random _rng = Random();

  static final Map<String, LiveBusStatus> _busStatuses = {
    'bus_12a': LiveBusStatus.approaching,
    'bus_24': LiveBusStatus.onTime,
    'bus_5b': LiveBusStatus.delayed,
    'bus_88': LiveBusStatus.onTime,
    'bus_20c': LiveBusStatus.notRunning,
  };

  List<LiveBusInfo> get allBuses => _allBuses;

  LiveBusInfo? getBusInfo(String busId) {
    try {
      return _allBuses.firstWhere((b) => b.busId == busId);
    } catch (_) {
      return null;
    }
  }

  Stream<LiveBusLocation> getLiveBusStream(String busId) {
    if (!_controllers.containsKey(busId)) {
      _controllers[busId] =
          StreamController<LiveBusLocation>.broadcast();
      _routeIndices[busId] = _rng.nextInt(4); // start mid-route
      _startSimulation(busId);
    }
    return _controllers[busId]!.stream;
  }

  void _startSimulation(String busId) {
    final info = getBusInfo(busId);
    if (info == null) return;

    final status = _busStatuses[busId] ?? LiveBusStatus.onTime;

    // Emit immediately
    _emitForBus(busId, info, status);

    // Then update every 4 seconds
    _timers[busId] = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_controllers[busId]?.hasListener ?? false) {
        _emitForBus(busId, info, status);
      }
    });
  }

  void _emitForBus(
      String busId, LiveBusInfo info, LiveBusStatus status) {
    final polyline = info.routePolyline;
    int idx = _routeIndices[busId] ?? 0;

    // Advance along route slowly
    if (status != LiveBusStatus.notRunning && idx < polyline.length - 1) {
      idx++;
      _routeIndices[busId] = idx;
    }

    final pt = polyline[idx];
    final stops = info.allStops;

    // Find current & next stop based on route progress
    final progress = idx / (polyline.length - 1);
    final stopIdx = (progress * (stops.length - 1)).floor().clamp(0, stops.length - 2);
    final currentStop = stops[stopIdx].name;
    final nextStop = stops[(stopIdx + 1).clamp(0, stops.length - 1)].name;
    final stopsAway = (stops.length - 1) - stopIdx;

    // Compute heading
    double heading = 90.0;
    if (idx > 0) {
      final prev = polyline[idx - 1];
      heading = _bearing(prev.lat, prev.lng, pt.lat, pt.lng);
    }

    // Mock ETA
    final speed = status == LiveBusStatus.delayed
        ? 18.0 + _rng.nextDouble() * 5
        : 25.0 + _rng.nextDouble() * 10;
    final etaMin = status == LiveBusStatus.notRunning
        ? 99
        : (stopsAway * 3 + _rng.nextInt(3)).clamp(1, 60);

    final location = LiveBusLocation(
      busId: busId,
      latitude: pt.lat,
      longitude: pt.lng,
      heading: heading,
      speedKmh: status == LiveBusStatus.notRunning ? 0 : speed,
      etaMinutes: etaMin,
      stopsAway: stopsAway,
      currentStop: currentStop,
      nextStop: nextStop,
      destination: info.destination,
      status: status,
      updatedAt: DateTime.now(),
    );

    _controllers[busId]?.add(location);
  }

  double _bearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * pi / 180;
    final lat1R = lat1 * pi / 180;
    final lat2R = lat2 * pi / 180;
    final y = sin(dLng) * cos(lat2R);
    final x =
        cos(lat1R) * sin(lat2R) - sin(lat1R) * cos(lat2R) * cos(dLng);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  /// Returns all buses sorted by distance to user position
  List<Map<String, dynamic>> getNearbyBusesSync(
      double userLat, double userLng) {
    final results = <Map<String, dynamic>>[];
    for (final info in _allBuses) {
      final idx = _routeIndices[info.busId] ?? 0;
      final pt = info.routePolyline[idx.clamp(0, info.routePolyline.length - 1)];
      final dist = _haversine(userLat, userLng, pt.lat, pt.lng);
      if (dist <= 15.0) {
        // 15 km radius for demo
        results.add({'info': info, 'distKm': dist});
      }
    }
    results.sort((a, b) =>
        (a['distKm'] as double).compareTo(b['distKm'] as double));
    return results;
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    for (final c in _controllers.values) {
      c.close();
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final mockLiveBusServiceProvider = Provider<MockLiveBusService>((ref) {
  final service = MockLiveBusService();
  ref.onDispose(service.dispose);
  return service;
});

final liveBusStreamProvider =
    StreamProvider.family<LiveBusLocation, String>((ref, busId) {
  final service = ref.watch(mockLiveBusServiceProvider);
  return service.getLiveBusStream(busId);
});

// Favorites (in-memory for now, can be persisted with shared_preferences)
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String busId) {
    if (state.contains(busId)) {
      state = {...state}..remove(busId);
    } else {
      state = {...state, busId};
    }
  }

  bool isFavorite(String busId) => state.contains(busId);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

// Recent searches
class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...state.where((s) => s != trimmed)];
    state = updated.take(8).toList();
  }

  void clear() => state = [];
  void remove(String query) => state = state.where((s) => s != query).toList();
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
        RecentSearchesNotifier.new);

// Selected bus for tracking
class SelectedTrackingBusNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? busId) => state = busId;
}

final selectedTrackingBusProvider =
    NotifierProvider<SelectedTrackingBusNotifier, String?>(
        SelectedTrackingBusNotifier.new);
