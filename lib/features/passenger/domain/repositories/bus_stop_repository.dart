import 'package:geolocator/geolocator.dart';
import '../models/bus_stop_info.dart';

abstract class BusStopRepository {
  Future<List<BusStopInfo>> getNearbyStops(Position? userPosition, {double preferredRadiusMeters = 500, double fallbackRadiusMeters = 2000});
  Future<List<BusStopInfo>> searchStops(String query);
  Future<BusStopInfo?> getStopByName(String name);
  Future<List<BusStopInfo>> getAllStops();
}
