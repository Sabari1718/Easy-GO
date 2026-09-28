import '../models/trip_model.dart';

abstract class TripRepository {
  Future<TripModel?> getCurrentTrip(String driverId);
  Future<TripModel> startTrip(String driverId, String busId, String routeId);
  Future<void> endTrip(String tripId);
}
