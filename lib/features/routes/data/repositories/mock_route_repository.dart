import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/route_model.dart';
import '../../domain/repositories/route_repository.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return MockRouteRepository();
});

class MockRouteRepository implements RouteRepository {
  final List<RouteModel> _mockRoutes = [
    const RouteModel(
      id: 'route_5',
      routeNumber: 'Route 5',
      routeName: 'Town Hall → Singanallur',
      stops: [
        BusStopModel(id: 's1', name: 'Town Hall', latitude: 10.9980, longitude: 76.9620),
        BusStopModel(id: 's2', name: 'Railway Station', latitude: 10.9990, longitude: 76.9660),
        BusStopModel(id: 's3', name: 'Singanallur', latitude: 11.0020, longitude: 77.0260),
      ],
      activeBusIds: ['bus_103', 'bus_104'],
    ),
    const RouteModel(
      id: 'route_12',
      routeNumber: 'Route 12',
      routeName: 'Gandhipuram → Ukkadam',
      stops: [
        BusStopModel(id: 's4', name: 'Gandhipuram', latitude: 11.0168, longitude: 76.9558),
        BusStopModel(id: 's5', name: 'Hopes College', latitude: 11.0250, longitude: 77.0100),
        BusStopModel(id: 's6', name: 'Ukkadam', latitude: 10.9910, longitude: 76.9620),
      ],
      activeBusIds: ['bus_101', 'bus_102'],
    ),
    const RouteModel(
      id: 'route_20',
      routeNumber: 'Route 20',
      routeName: 'Vadavalli → Marudhamalai',
      stops: [
        BusStopModel(id: 's7', name: 'Vadavalli', latitude: 11.0250, longitude: 76.9130),
        BusStopModel(id: 's8', name: 'Bharathiyar Uni', latitude: 11.0400, longitude: 76.8850),
        BusStopModel(id: 's9', name: 'Marudhamalai', latitude: 11.0470, longitude: 76.8520),
      ],
      activeBusIds: [],
    ),
  ];

  @override
  Future<List<RouteModel>> getActiveRoutes() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockRoutes.where((r) => r.activeBusIds.isNotEmpty).toList();
  }

  @override
  Future<List<RouteModel>> getPopularRoutes() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockRoutes.take(2).toList();
  }

  @override
  Future<List<RouteModel>> getRecentRoutes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [_mockRoutes[1]]; // Route 12
  }

  @override
  Future<RouteModel> getRouteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockRoutes.firstWhere((r) => r.id == id);
  }

  @override
  Future<List<RouteModel>> searchRoutes(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockRoutes.where((r) => 
      r.routeNumber.toLowerCase().contains(query.toLowerCase()) || 
      r.routeName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
