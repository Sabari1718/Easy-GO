import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/bus_stop_info.dart';
import '../../domain/repositories/bus_stop_repository.dart';

class MockBusStopRepository implements BusStopRepository {
  final List<BusStopInfo> _mockStops = [
    const BusStopInfo(
      id: 's_gandhipuram',
      name: 'Gandhipuram Bus Stop',
      latitude: 11.0168,
      longitude: 76.9558,
      address: 'Gandhipuram Central, Coimbatore',
      arrivingBuses: [
        StopArrivingBus(busId: 'bus_12a', busNumber: '12A', destination: 'Pollachi', etaMinutes: 5, status: 'Approaching'),
        StopArrivingBus(busId: 'bus_24', busNumber: '24', destination: 'Singanallur', etaMinutes: 9, status: 'On Time'),
        StopArrivingBus(busId: 'bus_5b', busNumber: '5B', destination: 'Kovaipudur', etaMinutes: 14, status: 'Delayed'),
      ],
    ),
    const BusStopInfo(
      id: 's_ukkadam',
      name: 'Ukkadam Bus Stand',
      latitude: 10.9902,
      longitude: 76.9607,
      address: 'Ukkadam, Coimbatore',
      arrivingBuses: [
        StopArrivingBus(busId: 'bus_12a', busNumber: '12A', destination: 'Pollachi', etaMinutes: 2, status: 'Approaching'),
        StopArrivingBus(busId: 'bus_102', busNumber: '102', destination: 'Town Hall', etaMinutes: 6, status: 'On Time'),
      ],
    ),
    const BusStopInfo(
      id: 's_madukkarai',
      name: 'Madukkarai Bus Stop',
      latitude: 10.9038,
      longitude: 76.9602,
      address: 'Madukkarai Main Road, NH-83',
      arrivingBuses: [
        StopArrivingBus(busId: 'bus_12a', busNumber: '12A', destination: 'Pollachi', etaMinutes: 12, status: 'On Time'),
        StopArrivingBus(busId: 'bus_24', busNumber: '24', destination: 'Gandhipuram', etaMinutes: 18, status: 'On Time'),
      ],
    ),
    const BusStopInfo(
      id: 's_townhall',
      name: 'Town Hall Stop',
      latitude: 10.9980,
      longitude: 76.9620,
      address: 'Town Hall, Coimbatore',
      arrivingBuses: [
        StopArrivingBus(busId: 'bus_103', busNumber: '5', destination: 'Singanallur', etaMinutes: 4, status: 'On Time'),
        StopArrivingBus(busId: 'bus_12a', busNumber: '12A', destination: 'Ukkadam', etaMinutes: 8, status: 'On Time'),
      ],
    ),
    const BusStopInfo(
      id: 's_rspuram',
      name: 'RS Puram West',
      latitude: 11.0080,
      longitude: 76.9480,
      address: 'RS Puram, Coimbatore',
      arrivingBuses: [
        StopArrivingBus(busId: 'bus_5b', busNumber: '5B', destination: 'Kovaipudur', etaMinutes: 7, status: 'On Time'),
      ],
    ),
    const BusStopInfo(
      id: 's_singanallur',
      name: 'Singanallur Bus Terminal',
      latitude: 11.0020,
      longitude: 77.0260,
      address: 'Singanallur, Coimbatore',
      arrivingBuses: [
        StopArrivingBus(busId: 'bus_24', busNumber: '24', destination: 'Gandhipuram', etaMinutes: 3, status: 'Approaching'),
      ],
    ),
    const BusStopInfo(
      id: 's_kinathukadavu',
      name: 'Kinathukadavu Bus Stop',
      latitude: 10.8174,
      longitude: 77.0194,
      address: 'Kinathukadavu, NH-83',
      arrivingBuses: [
        StopArrivingBus(busId: 'bus_12a', busNumber: '12A', destination: 'Pollachi', etaMinutes: 15, status: 'On Time'),
      ],
    ),
    const BusStopInfo(
      id: 's_pollachi',
      name: 'Pollachi Bus Station',
      latitude: 10.6588,
      longitude: 77.0090,
      address: 'Pollachi Central',
      arrivingBuses: [
        StopArrivingBus(busId: 'bus_12a', busNumber: '12A', destination: 'Coimbatore', etaMinutes: 1, status: 'Approaching'),
      ],
    ),
  ];

  @override
  Future<List<BusStopInfo>> getAllStops() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockStops;
  }

  @override
  Future<List<BusStopInfo>> getNearbyStops(Position? userPosition, {double preferredRadiusMeters = 500, double fallbackRadiusMeters = 2000}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (userPosition == null) {
      // Return first 3 as default when position not available
      return _mockStops.take(3).toList();
    }

    final List<Map<String, dynamic>> scored = _mockStops.map((stop) {
      double dist = Geolocator.distanceBetween(
        userPosition.latitude, userPosition.longitude,
        stop.latitude, stop.longitude,
      );
      return {'stop': stop, 'distance': dist};
    }).toList();

    scored.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    // Try preferred radius first (500m)
    var filtered = scored.where((e) => (e['distance'] as double) <= preferredRadiusMeters).toList();

    // If none within 500m, fallback to 2km
    if (filtered.isEmpty) {
      filtered = scored.where((e) => (e['distance'] as double) <= fallbackRadiusMeters).toList();
    }

    // If still empty, return closest 3 stops
    if (filtered.isEmpty) {
      return scored.take(3).map((e) => e['stop'] as BusStopInfo).toList();
    }

    return filtered.map((e) => e['stop'] as BusStopInfo).toList();
  }

  @override
  Future<List<BusStopInfo>> searchStops(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return [];
    return _mockStops.where((s) =>
      s.name.toLowerCase().contains(lower) ||
      s.address.toLowerCase().contains(lower)
    ).toList();
  }

  @override
  Future<BusStopInfo?> getStopByName(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lower = name.toLowerCase().trim();
    try {
      return _mockStops.firstWhere((s) => s.name.toLowerCase() == lower || s.name.toLowerCase().contains(lower));
    } catch (_) {
      return null;
    }
  }
}

final busStopRepositoryProvider = Provider<BusStopRepository>((ref) {
  return MockBusStopRepository();
});
