import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/passenger/data/services/passenger_discovery_service.dart';
import '../../features/passenger/domain/models/home_discovery_data.dart';
import '../../features/passenger/domain/models/journey_model.dart';
import 'location_provider.dart';

final homeDiscoveryProvider = FutureProvider<HomeDiscoveryData?>((ref) async {
  final locationState = ref.watch(locationProvider);

  if (!locationState.isLocationEnabled || locationState.currentPosition == null) {
    return null;
  }

  final service = ref.watch(passengerDiscoveryServiceProvider);
  return service.getHomeDiscovery(
    locationState.currentPosition,
    fallbackAddress: locationState.address,
  );
});

class JourneySearchState {
  final bool isLoading;
  final JourneySearchResult? result;
  final String? error;

  const JourneySearchState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  JourneySearchState copyWith({
    bool? isLoading,
    JourneySearchResult? result,
    String? error,
  }) {
    return JourneySearchState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
    );
  }
}

class JourneySearchNotifier extends Notifier<JourneySearchState> {
  @override
  JourneySearchState build() => const JourneySearchState();

  Future<void> search({
    required String from,
    required String to,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final locationState = ref.read(locationProvider);
      final service = ref.read(passengerDiscoveryServiceProvider);
      final res = await service.planJourney(
        from: from,
        to: to,
        userPos: locationState.currentPosition,
      );
      state = state.copyWith(isLoading: false, result: res);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final journeySearchProvider =
    NotifierProvider<JourneySearchNotifier, JourneySearchState>(() {
  return JourneySearchNotifier();
});
