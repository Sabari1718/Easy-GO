import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class BusModel {
  final String busId;
  final String busNumber;
  final String route;
  final double latitude;
  final double longitude;
  final String status;
  final String eta;
  final String occupancy;

  BusModel({
    required this.busId,
    required this.busNumber,
    required this.route,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.eta,
    required this.occupancy,
  });
}

class MockBusRepository {
  final List<BusModel> _mockBuses = [
    BusModel(busId: 'b1', busNumber: '102', route: '12', latitude: 11.0183, longitude: 76.9725, status: 'On Route', eta: '6 min', occupancy: 'Crowded'),
    BusModel(busId: 'b2', busNumber: '205', route: '5', latitude: 11.0200, longitude: 76.9700, status: 'On Route', eta: '10 min', occupancy: 'Seats Available'),
    BusModel(busId: 'b3', busNumber: '301', route: '20', latitude: 11.0150, longitude: 76.9800, status: 'On Route', eta: '14 min', occupancy: 'Few Seats'),
    BusModel(busId: 'b4', busNumber: 'A1', route: '11', latitude: 11.0300, longitude: 76.9500, status: 'Stopped', eta: '20 min', occupancy: 'Empty'),
  ];

  Future<List<BusModel>> getNearbyBuses(Position? userPosition) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Mock network
    if (userPosition == null) return [];

    // Sort by distance if userPosition is provided
    final List<Map<String, dynamic>> busDistances = _mockBuses.map((bus) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude, userPosition.longitude,
        bus.latitude, bus.longitude,
      );
      return {'bus': bus, 'distance': distance};
    }).toList();

    busDistances.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return busDistances.map((e) => e['bus'] as BusModel).take(5).toList();
  }

  Future<List<BusModel>> searchBuses(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowerQuery = query.toLowerCase();
    return _mockBuses.where((bus) {
      return bus.busNumber.toLowerCase().contains(lowerQuery) ||
             bus.route.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

final mockBusRepositoryProvider = Provider<MockBusRepository>((ref) {
  return MockBusRepository();
});
