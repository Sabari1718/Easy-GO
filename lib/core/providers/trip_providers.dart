import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/driver/domain/models/trip_model.dart';
import '../../features/driver/data/repositories/mock_trip_repository.dart';
import 'auth_providers.dart';
import '../../features/auth/domain/models/user_model.dart';

final currentTripProvider = FutureProvider<TripModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.role != UserRole.driver) return null;
  
  final repository = ref.watch(tripRepositoryProvider);
  return await repository.getCurrentTrip(user.id);
});

final tripControllerProvider = AsyncNotifierProvider<TripController, void>(() {
  return TripController();
});

class TripController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> startTrip(String busId, String routeId) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final repo = ref.read(tripRepositoryProvider);
        await repo.startTrip(user.id, busId, routeId);
        ref.invalidate(currentTripProvider);
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endTrip(String tripId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(tripRepositoryProvider);
      await repo.endTrip(tripId);
      ref.invalidate(currentTripProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
