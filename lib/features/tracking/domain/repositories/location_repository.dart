import '../models/bus_location_model.dart';

abstract class LocationRepository {
  Stream<BusLocationModel> getBusLocationStream(String busId);
  Future<void> updateDriverLocation(String busId, double lat, double lng, double heading);
  Future<void> startLocationSimulation(String busId, String routeId);
  Future<void> stopLocationSimulation();
}
