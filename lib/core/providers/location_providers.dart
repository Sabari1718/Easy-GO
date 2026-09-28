import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tracking/domain/models/bus_location_model.dart';
import '../../features/tracking/data/repositories/mock_location_repository.dart';

final busLocationStreamProvider = StreamProvider.family<BusLocationModel, String>((ref, busId) {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getBusLocationStream(busId);
});

final locationSimulationControllerProvider = Provider<LocationSimulationController>((ref) {
  return LocationSimulationController(ref);
});

class LocationSimulationController {
  final Ref _ref;

  LocationSimulationController(this._ref);

  void startSimulation(String busId, String routeId) {
    _ref.read(locationRepositoryProvider).startLocationSimulation(busId, routeId);
  }

  void stopSimulation() {
    _ref.read(locationRepositoryProvider).stopLocationSimulation();
  }
}
