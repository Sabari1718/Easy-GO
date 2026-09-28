import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bus_model.dart';
import '../../domain/repositories/bus_repository.dart';

final busRepositoryProvider = Provider<BusRepository>((ref) {
  return MockBusRepository();
});

class MockBusRepository implements BusRepository {
  final List<BusModel> _mockBuses = [
    const BusModel(
      id: 'bus_101',
      busNumber: 'BUS 101',
      routeId: 'route_12',
      status: BusStatus.onRoute,
      nextStopId: 's5',
      etaMinutes: 12,
    ),
    const BusModel(
      id: 'bus_102',
      busNumber: 'BUS 102',
      routeId: 'route_12',
      status: BusStatus.onRoute,
      nextStopId: 's4',
      etaMinutes: 6,
    ),
    const BusModel(
      id: 'bus_103',
      busNumber: 'BUS 103',
      routeId: 'route_5',
      status: BusStatus.full,
      nextStopId: 's2',
      etaMinutes: 4,
    ),
    const BusModel(
      id: 'bus_104',
      busNumber: 'BUS 104',
      routeId: 'route_5',
      status: BusStatus.notFull,
      nextStopId: 's3',
      etaMinutes: 18,
    ),
  ];

  @override
  Future<List<BusModel>> getBusesForRoute(String routeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockBuses.where((b) => b.routeId == routeId).toList();
  }

  @override
  Future<BusModel> getBusById(String busId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockBuses.firstWhere((b) => b.id == busId);
  }

  @override
  Future<void> updateBusStatus(String busId, BusStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockBuses.indexWhere((b) => b.id == busId);
    if (index != -1) {
      _mockBuses[index] = _mockBuses[index].copyWith(status: status);
    }
  }
}
