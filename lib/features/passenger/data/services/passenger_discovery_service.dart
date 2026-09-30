import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/models/bus_stop_info.dart';
import '../../domain/models/home_discovery_data.dart';
import '../../domain/models/journey_model.dart';
import '../../domain/repositories/bus_stop_repository.dart';
import '../repositories/mock_bus_stop_repository.dart';
import 'mock_live_bus_service.dart';

final passengerDiscoveryServiceProvider =
    Provider<PassengerDiscoveryService>((ref) {
  final busService = ref.watch(mockLiveBusServiceProvider);
  final stopRepo = ref.watch(busStopRepositoryProvider);
  return PassengerDiscoveryService(busService, stopRepo);
});

class PassengerDiscoveryService {
  final MockLiveBusService _busService;
  final BusStopRepository _stopRepo;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 1500),
    receiveTimeout: const Duration(milliseconds: 1500),
  ));

  PassengerDiscoveryService(this._busService, this._stopRepo);

  // ─── 1. Home Discovery Data ────────────────────────────────────────────────
  Future<HomeDiscoveryData?> getHomeDiscovery(Position? userPos,
      {String? fallbackAddress}) async {
    if (userPos == null) return null;

    final lat = userPos.latitude;
    final lng = userPos.longitude;

    // Attempt backend API first
    try {
      final res = await _dio.get('${ApiConstants.baseUrl}/home', queryParameters: {
        'latitude': lat,
        'longitude': lng,
      });
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final buses = (data['nearbyBuses'] as List<dynamic>? ?? [])
            .map((b) => NearbyBusItem.fromJson(b as Map<String, dynamic>))
            .toList();
        final stops = (data['nearbyStops'] as List<dynamic>? ?? [])
            .map((s) => BusStopInfo(
                  id: s['id'] ?? '',
                  name: s['name'] ?? '',
                  latitude: (s['latitude'] as num?)?.toDouble() ?? 0.0,
                  longitude: (s['longitude'] as num?)?.toDouble() ?? 0.0,
                  address: s['address'] ?? '',
                  arrivingBuses: (s['arrivingBuses'] as List<dynamic>? ?? [])
                      .map((ab) => StopArrivingBus(
                            busId: ab['busId'] ?? '',
                            busNumber: ab['busNumber'] ?? '',
                            destination: ab['destination'] ?? '',
                            etaMinutes: (ab['etaMinutes'] as num?)?.toInt() ?? 5,
                            status: ab['status'] ?? 'On Time',
                          ))
                      .toList(),
                ))
            .toList();
        final routes = (data['nearbyRoutes'] as List<dynamic>? ?? [])
            .map((r) => NearbyRouteItem.fromJson(r as Map<String, dynamic>))
            .toList();

        return HomeDiscoveryData(
          locationSummary: data['locationSummary'] as String? ??
              fallbackAddress ??
              'Your Location',
          latitude: lat,
          longitude: lng,
          nearbyBuses: buses,
          nearbyStops: stops,
          nearbyRoutes: routes,
        );
      }
    } catch (_) {
      // Backend unavailable, compute locally with real GPS location
    }

    // ── Local Location-Aware Computation with real GPS coordinates ─────────
    final allStops = await _stopRepo.getAllStops();

    // 1. Find nearby bus stops (within 500m preferred, expanding up to 2.5 km)
    final scoredStops = allStops.map((stop) {
      final d = Geolocator.distanceBetween(
          lat, lng, stop.latitude, stop.longitude);
      return {'stop': stop, 'distMeters': d};
    }).toList();

    scoredStops.sort((a, b) =>
        (a['distMeters'] as double).compareTo(b['distMeters'] as double));

    var nearbyStopsScored = scoredStops
        .where((e) => (e['distMeters'] as double) <= 500)
        .toList();
    if (nearbyStopsScored.isEmpty) {
      nearbyStopsScored = scoredStops
          .where((e) => (e['distMeters'] as double) <= 2500)
          .toList();
    }
    if (nearbyStopsScored.isEmpty) {
      nearbyStopsScored = scoredStops.take(3).toList();
    }

    final nearbyStops = nearbyStopsScored
        .take(4)
        .map((e) => e['stop'] as BusStopInfo)
        .toList();

    final nearestStop = nearbyStops.isNotEmpty ? nearbyStops.first : null;
    final locationSummary = nearestStop != null
        ? '${nearestStop.name}, Coimbatore'
        : (fallbackAddress ?? 'Coimbatore');

    // 2. Find nearby buses (within 5 km radius)
    final allBuses = _busService.allBuses;
    final List<NearbyBusItem> nearbyBuses = [];
    final Set<String> nearbyRouteNumbers = {};

    for (final bus in allBuses) {
      // Find distance to bus's current location or nearest route point
      double minRouteDist = double.infinity;
      for (final pt in bus.routePolyline) {
        final d = Geolocator.distanceBetween(lat, lng, pt.lat, pt.lng);
        if (d < minRouteDist) minRouteDist = d;
      }

      final distKm = minRouteDist / 1000;

      // Filter: strictly <= 5 km
      if (distKm <= 5.0) {
        nearbyRouteNumbers.add(bus.busNumber);
        final eta = (distKm * 3.5).round().clamp(2, 25);
        nearbyBuses.add(NearbyBusItem(
          busId: bus.busId,
          busNumber: bus.busNumber,
          routeId: bus.routeId,
          routeName: '${bus.origin} → ${bus.destination}',
          origin: bus.origin,
          destination: bus.destination,
          distanceKm: Math.round(distKm * 10) / 10,
          etaMinutes: eta,
          isLive: true,
          status: 'LIVE NOW',
          currentStop: bus.allStops.first.name,
          nextStop: bus.allStops.length > 1
              ? bus.allStops[1].name
              : bus.destination,
          speed: 28.0,
        ));
      }
    }

    // Sort: Nearest first
    nearbyBuses.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // 3. Nearby routes (unique routes serving user's immediate area)
    final nearbyRoutes = nearbyBuses
        .map((b) => NearbyRouteItem(
              routeId: b.routeId,
              routeNumber: b.busNumber,
              routeName: b.routeName,
              source: b.origin,
              destination: b.destination,
              activeBusCount: 1,
            ))
        .fold<Map<String, NearbyRouteItem>>({}, (map, item) {
          map[item.routeNumber] = item;
          return map;
        })
        .values
        .toList();

    return HomeDiscoveryData(
      locationSummary: locationSummary,
      latitude: lat,
      longitude: lng,
      nearbyBuses: nearbyBuses,
      nearbyStops: nearbyStops,
      nearbyRoutes: nearbyRoutes,
    );
  }

  // ─── 2. Journey Discovery & Trip Planning (Destination / From → To) ────────
  Future<JourneySearchResult> planJourney({
    required String from,
    required String to,
    Position? userPos,
  }) async {
    final fromQuery = from.trim().isEmpty ? 'Current Location' : from.trim();
    final toQuery = to.trim();

    // 1. Try Backend API
    try {
      final queryParams = {
        'from': fromQuery,
        'to': toQuery,
        if (userPos != null) 'fromLat': userPos.latitude.toString(),
        if (userPos != null) 'fromLng': userPos.longitude.toString(),
      };
      final res = await _dio.get('${ApiConstants.baseUrl}/journeys/search',
          queryParameters: queryParams);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return JourneySearchResult.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Local fallback
    }

    // ── Local Fallback Calculation ──────────────────────────────────────────
    final allStops = await _stopRepo.getAllStops();
    final userLat = userPos?.latitude ?? 11.0168; // Default Gandhipuram
    final userLng = userPos?.longitude ?? 76.9558;

    // Recommended boarding stop
    BusStopInfo boardingStop = allStops.first;
    double minBoardingDist = double.infinity;
    for (final s in allStops) {
      final d = Geolocator.distanceBetween(
          userLat, userLng, s.latitude, s.longitude);
      if (d < minBoardingDist) {
        minBoardingDist = d;
        boardingStop = s;
      }
    }

    final walkDistMeters = minBoardingDist.round();
    final walkMinutes = (walkDistMeters / 80).round().clamp(1, 20);

    // Alternative boarding stop
    final alternativeStops = allStops
        .where((s) => s.id != boardingStop.id)
        .map((s) => {
              'stop': s,
              'dist': Geolocator.distanceBetween(
                  userLat, userLng, s.latitude, s.longitude)
            })
        .where((e) => (e['dist'] as double) <= 1200)
        .take(2)
        .map((e) {
      final s = e['stop'] as BusStopInfo;
      final d = (e['dist'] as double).round();
      return JourneyStop(
        id: s.id,
        name: s.name,
        latitude: s.latitude,
        longitude: s.longitude,
        distanceMeters: d.toDouble(),
        walkMinutes: (d / 80).round().clamp(1, 25),
      );
    }).toList();

    // Destination stop
    BusStopInfo destStop = allStops.last;
    final lowerTo = toQuery.toLowerCase();
    for (final s in allStops) {
      if (s.name.toLowerCase().contains(lowerTo)) {
        destStop = s;
        break;
      }
    }

    // Find direct buses
    final allBuses = _busService.allBuses;
    final List<JourneyBusOption> directRoutes = [];

    for (final b in allBuses) {
      final hasFrom = b.origin.toLowerCase().contains(boardingStop.name.toLowerCase()) ||
          b.allStops.any((s) => s.name.toLowerCase().contains(boardingStop.name.toLowerCase())) ||
          fromQuery.toLowerCase() == 'current location';
      final hasTo = b.destination.toLowerCase().contains(lowerTo) ||
          b.allStops.any((s) => s.name.toLowerCase().contains(lowerTo));

      if (hasFrom && hasTo) {
        final isLive = b.busId == 'bus_12a' || b.busId == 'bus_24';
        directRoutes.add(JourneyBusOption(
          busId: b.busId,
          busNumber: b.busNumber,
          routeId: b.routeId,
          routeName: '${b.origin} → ${b.destination}',
          origin: b.origin,
          destination: b.destination,
          isLive: isLive,
          statusLabel: isLive ? 'LIVE NOW' : 'UPCOMING',
          currentLocation: isLive ? 'Madukkarai' : boardingStop.name,
          nextStop: isLive ? 'Ettimadai' : b.allStops.first.name,
          etaMinutes: isLive ? 8 : 18,
          journeyDuration: '1h 20m',
          walkingDistanceMeters: walkDistMeters.toDouble(),
          walkingMinutes: walkMinutes,
          boardingStopName: boardingStop.name,
          destinationStopName: destStop.name,
          isDirect: true,
          transfers: 0,
          legs: [
            JourneyLeg(
              type: 'WALK',
              title: 'Walk to boarding stop',
              instruction: 'Walk $walkDistMeters m ($walkMinutes min) to ${boardingStop.name}',
              durationMinutes: walkMinutes,
              toStop: boardingStop.name,
            ),
            JourneyLeg(
              type: 'BUS',
              title: 'Bus ${b.busNumber}',
              instruction: 'Ride ${b.busNumber} from ${boardingStop.name} to ${destStop.name}',
              durationMinutes: 80,
              busNumber: b.busNumber,
              fromStop: boardingStop.name,
              toStop: destStop.name,
            ),
          ],
        ));
      }
    }

    // Connecting route option (Transfer at Ukkadam hub)
    final connectingRoutes = <JourneyBusOption>[
      JourneyBusOption(
        busId: 'transfer_opt_1',
        busNumber: '12A + 24',
        routeId: 'conn_1',
        routeName: '${boardingStop.name} → Ukkadam → ${destStop.name}',
        origin: boardingStop.name,
        destination: destStop.name,
        isLive: true,
        statusLabel: 'LIVE NOW',
        currentLocation: 'Madukkarai',
        nextStop: 'Ettimadai',
        etaMinutes: 6,
        journeyDuration: '1h 45m',
        walkingDistanceMeters: walkDistMeters.toDouble(),
        walkingMinutes: walkMinutes,
        boardingStopName: boardingStop.name,
        destinationStopName: destStop.name,
        isDirect: false,
        transfers: 1,
        legs: [
          JourneyLeg(
            type: 'WALK',
            title: 'Walk to ${boardingStop.name}',
            instruction: 'Walk $walkMinutes min to ${boardingStop.name}',
            durationMinutes: walkMinutes,
            toStop: boardingStop.name,
          ),
          const JourneyLeg(
            type: 'BUS',
            title: 'Bus 12A',
            instruction: 'Take 12A toward Ukkadam (25 min)',
            durationMinutes: 25,
            busNumber: '12A',
            fromStop: 'Gandhipuram',
            toStop: 'Ukkadam',
          ),
          const JourneyLeg(
            type: 'TRANSFER',
            title: 'Transfer at Ukkadam',
            instruction: 'Transfer wait at Ukkadam (~8 min)',
            durationMinutes: 8,
            fromStop: 'Ukkadam',
          ),
          JourneyLeg(
            type: 'BUS',
            title: 'Bus 24',
            instruction: 'Take 24 toward ${destStop.name} (65 min)',
            durationMinutes: 65,
            busNumber: '24',
            fromStop: 'Ukkadam',
            toStop: destStop.name,
          ),
        ],
      ),
    ];

    return JourneySearchResult(
      fromQuery: fromQuery,
      toQuery: toQuery,
      recommendedBoardingStop: JourneyStop(
        id: boardingStop.id,
        name: boardingStop.name,
        latitude: boardingStop.latitude,
        longitude: boardingStop.longitude,
        distanceMeters: walkDistMeters.toDouble(),
        walkMinutes: walkMinutes,
      ),
      alternativeBoardingStops: alternativeStops,
      destinationStop: JourneyStop(
        id: destStop.id,
        name: destStop.name,
        latitude: destStop.latitude,
        longitude: destStop.longitude,
        distanceMeters: 400.0,
        walkMinutes: 5,
      ),
      directRoutes: directRoutes,
      connectingRoutes: connectingRoutes,
      allOptions: [...directRoutes, ...connectingRoutes],
    );
  }
}

class Math {
  static double round(double v) => (v * 10).round() / 10;
}
