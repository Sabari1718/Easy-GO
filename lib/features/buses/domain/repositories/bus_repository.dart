import '../models/bus_model.dart';

abstract class BusRepository {
  Future<List<BusModel>> getBusesForRoute(String routeId);
  Future<BusModel> getBusById(String busId);
  Future<void> updateBusStatus(String busId, BusStatus status);
}
