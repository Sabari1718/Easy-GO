import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/buses/domain/models/bus_model.dart';
import '../../features/buses/data/repositories/mock_bus_repository.dart';

final routeBusesProvider = FutureProvider.family<List<BusModel>, String>((ref, routeId) async {
  final repository = ref.watch(busRepositoryProvider);
  return await repository.getBusesForRoute(routeId);
});

final selectedBusProvider = FutureProvider.family<BusModel, String>((ref, busId) async {
  final repository = ref.watch(busRepositoryProvider);
  return await repository.getBusById(busId);
});

// For driver to update status
final updateBusStatusProvider = FutureProvider.family<void, ({String busId, BusStatus status})>((ref, args) async {
  final repository = ref.watch(busRepositoryProvider);
  await repository.updateBusStatus(args.busId, args.status);
  ref.invalidate(selectedBusProvider(args.busId));
});
