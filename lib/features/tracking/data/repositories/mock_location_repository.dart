import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bus_location_model.dart';
import '../../domain/repositories/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return MockLocationRepository();
});

class MockLocationRepository implements LocationRepository {
  final Map<String, StreamController<BusLocationModel>> _streams = {};
  Timer? _simulationTimer;

  @override
  Stream<BusLocationModel> getBusLocationStream(String busId) {
    if (!_streams.containsKey(busId)) {
      _streams[busId] = StreamController<BusLocationModel>.broadcast();
      
      // Emit initial mock location based on busId
      if (busId == 'bus_101' || busId == 'bus_102') {
        _streams[busId]!.add(BusLocationModel(
          busId: busId,
          latitude: 11.0168,
          longitude: 76.9558,
          heading: 90.0,
        ));
      } else {
        _streams[busId]!.add(BusLocationModel(
          busId: busId,
          latitude: 10.9980,
          longitude: 76.9620,
          heading: 45.0,
        ));
      }
    }
    return _streams[busId]!.stream;
  }

  @override
  Future<void> updateDriverLocation(String busId, double lat, double lng, double heading) async {
    if (_streams.containsKey(busId)) {
      _streams[busId]!.add(BusLocationModel(
        busId: busId,
        latitude: lat,
        longitude: lng,
        heading: heading,
      ));
    }
  }

  @override
  Future<void> startLocationSimulation(String busId, String routeId) async {
    stopLocationSimulation();
    
    double currentLat = 11.0168;
    double currentLng = 76.9558;
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      currentLat += 0.0001;
      currentLng += 0.0001;
      updateDriverLocation(busId, currentLat, currentLng, 45.0);
    });
  }

  @override
  Future<void> stopLocationSimulation() async {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }
}
