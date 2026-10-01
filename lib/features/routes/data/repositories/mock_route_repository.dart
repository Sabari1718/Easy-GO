import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/route_model.dart';
import '../../domain/repositories/route_repository.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return MockRouteRepository();
});

class MockRouteRepository implements RouteRepository {
  final List<RouteModel> _mockRoutes = [
    const RouteModel(
      id: 'r12a',
      routeNumber: '12A',
      routeName: 'Gandhipuram → Ukkadam',
      stops: [
        BusStopModel(id: 's1', name: 'Gandhipuram', latitude: 11.0168, longitude: 76.9558),
        BusStopModel(id: 's2', name: 'Railway Station', latitude: 10.9990, longitude: 76.9660),
        BusStopModel(id: 's3', name: 'Town Hall', latitude: 10.9980, longitude: 76.9620),
        BusStopModel(id: 's4', name: 'Ukkadam', latitude: 10.9910, longitude: 76.9620),
      ],
      activeBusIds: ['bus_12a_1', 'bus_12a_2', 'bus_12a_3'],
    ),
    const RouteModel(
      id: 'r24',
      routeNumber: '24',
      routeName: 'Gandhipuram → Singanallur',
      stops: [
        BusStopModel(id: 's4', name: 'Gandhipuram', latitude: 11.0168, longitude: 76.9558),
        BusStopModel(id: 's5', name: 'Hopes College', latitude: 11.0250, longitude: 77.0100),
        BusStopModel(id: 's6', name: 'Singanallur', latitude: 11.0020, longitude: 77.0260),
      ],
      activeBusIds: ['bus_24_1', 'bus_24_2'],
    ),
    const RouteModel(
      id: 'r5b',
      routeNumber: '5B',
      routeName: 'RS Puram → Kovaipudur',
      stops: [
        BusStopModel(id: 's7', name: 'RS Puram', latitude: 11.0070, longitude: 76.9480),
        BusStopModel(id: 's8', name: 'Kuniamuthur', latitude: 10.9630, longitude: 76.9550),
        BusStopModel(id: 's9', name: 'Kovaipudur', latitude: 10.9410, longitude: 76.9440),
      ],
      activeBusIds: ['bus_5b_1'],
    ),
    const RouteModel(
      id: 'r88',
      routeNumber: '88',
      routeName: 'Vadavalli → Tiruppur',
      stops: [
        BusStopModel(id: 's10', name: 'Vadavalli', latitude: 11.0250, longitude: 76.9130),
        BusStopModel(id: 's11', name: 'Gandhipuram', latitude: 11.0168, longitude: 76.9558),
        BusStopModel(id: 's12', name: 'Tiruppur', latitude: 11.1080, longitude: 77.3410),
      ],
      activeBusIds: ['bus_88_1', 'bus_88_2'],
    ),
    const RouteModel(
      id: 'r20c',
      routeNumber: '20C',
      routeName: 'Mettupalayam → Coimbatore',
      stops: [
        BusStopModel(id: 's13', name: 'Mettupalayam', latitude: 11.3000, longitude: 76.9330),
        BusStopModel(id: 's14', name: 'Thudiyalur', latitude: 11.0830, longitude: 76.9380),
        BusStopModel(id: 's15', name: 'Gandhipuram', latitude: 11.0168, longitude: 76.9558),
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
    return [_mockRoutes[1]];
  }

  @override
  Future<RouteModel?> getRouteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockRoutes.indexWhere((r) => r.id == id);
    if (index != -1) return _mockRoutes[index];
    return null;
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
