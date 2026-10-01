import '../models/route_model.dart';

abstract class RouteRepository {
  Future<List<RouteModel>> getActiveRoutes();
  Future<List<RouteModel>> getPopularRoutes();
  Future<List<RouteModel>> getRecentRoutes();
  Future<RouteModel?> getRouteById(String id);
  Future<List<RouteModel>> searchRoutes(String query);
}
