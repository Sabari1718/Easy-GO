import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/trip_model.dart';
import '../../domain/repositories/trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return MockTripRepository();
});

class MockTripRepository implements TripRepository {
  TripModel? _currentTrip;

  @override
  Future<TripModel?> getCurrentTrip(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentTrip;
  }

  @override
  Future<TripModel> startTrip(String driverId, String busId, String routeId) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentTrip = TripModel(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      driverId: driverId,
      busId: busId,
      routeId: routeId,
      status: TripStatus.active,
      startTime: DateTime.now(),
    );
    return _currentTrip!;
  }

  @override
  Future<void> endTrip(String tripId) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_currentTrip != null && _currentTrip!.id == tripId) {
      _currentTrip = _currentTrip!.copyWith(
        status: TripStatus.completed,
        endTime: DateTime.now(),
      );
      _currentTrip = null; // Clear active trip
    }
  }
}
