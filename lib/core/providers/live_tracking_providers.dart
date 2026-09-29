import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/passenger/domain/models/bus_live_state.dart';
import '../../features/passenger/domain/repositories/live_bus_tracking_repository.dart';
import '../../features/passenger/data/repositories/mock_live_bus_tracking_repository.dart';

final liveBusTrackingRepositoryProvider =
    Provider<LiveBusTrackingRepository>((ref) {
  return MockLiveBusTrackingRepository();
});

final busLiveStateStreamProvider =
    StreamProvider.family<BusLiveState, String>((ref, busId) {
  final repo = ref.watch(liveBusTrackingRepositoryProvider);
  return repo.watchBus(busId);
});
