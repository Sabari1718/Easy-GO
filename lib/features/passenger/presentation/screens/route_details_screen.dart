import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/route_providers.dart';
import '../../../../core/providers/bus_providers.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';

class RouteDetailsScreen extends ConsumerWidget {
  final String routeId;

  const RouteDetailsScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(selectedRouteProvider(routeId));
    final busesAsync = ref.watch(routeBusesProvider(routeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Route Details')),
      body: routeAsync.when(
        data: (route) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.routeNumber, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(route.routeName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 24),
                      const Text('Stops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...route.stops.map((stop) => ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.red),
                        title: Text(stop.name),
                        contentPadding: EdgeInsets.zero,
                      )),
                      const SizedBox(height: 24),
                      const Text('Active Buses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              busesAsync.when(
                data: (buses) {
                  if (buses.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No active buses on this route.'),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bus = buses[index];
                        return AppCard(
                          onTap: () {
                            context.push('/passenger/bus/${bus.id}');
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bus.busNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('ETA: ${bus.etaMinutes} mins', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              StatusChip(status: bus.status),
                            ],
                          ),
                        );
                      },
                      childCount: buses.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (err, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
