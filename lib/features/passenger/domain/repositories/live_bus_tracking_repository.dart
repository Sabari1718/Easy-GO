import '../models/bus_live_state.dart';

abstract class LiveBusTrackingRepository {
  Stream<BusLiveState> watchBus(String busId);
  Future<BusLiveState> getCurrentBusState(String busId);
  void selectPassengerStop(String busId, String? stopId);
  void startBus(String busId);
  void pauseBus(String busId);
  void resumeBus(String busId);
  void skipToNextStop(String busId);
  void resetJourney(String busId);
  void setSpeedMultiplier(String busId, double multiplier);
}
