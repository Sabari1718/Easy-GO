import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/routes/domain/models/route_model.dart';
import '../../features/routes/data/repositories/mock_route_repository.dart';

final routesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final repository = ref.watch(routeRepositoryProvider);
  return await repository.getActiveRoutes();
});

final popularRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final repository = ref.watch(routeRepositoryProvider);
  return await repository.getPopularRoutes();
});

final recentRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final repository = ref.watch(routeRepositoryProvider);
  return await repository.getRecentRoutes();
});

final selectedRouteProvider = FutureProvider.family<RouteModel?, String>((ref, id) async {
  final repository = ref.watch(routeRepositoryProvider);
  return await repository.getRouteById(id);
});

class RouteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final routeSearchQueryProvider = NotifierProvider<RouteSearchQueryNotifier, String>(() {
  return RouteSearchQueryNotifier();
});

final searchRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final query = ref.watch(routeSearchQueryProvider);
  final repository = ref.watch(routeRepositoryProvider);
  if (query.isEmpty) {
    return [];
  }
  return await repository.searchRoutes(query);
});
