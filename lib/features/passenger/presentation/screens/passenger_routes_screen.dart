import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/route_providers.dart';
import '../../../../core/widgets/app_card.dart';

class PassengerRoutesScreen extends ConsumerWidget {
  const PassengerRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(routeSearchQueryProvider);
    final routesAsync = query.isEmpty ? ref.watch(routesProvider) : ref.watch(searchRoutesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Routes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search routes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                ref.read(routeSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: routesAsync.when(
              data: (routes) {
                if (routes.isEmpty) {
                  return const Center(child: Text('No routes found.'));
                }
                return ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return AppCard(
                      onTap: () {
                        context.push('/passenger/route/${route.id}');
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(route.routeNumber.split(' ').last),
                        ),
                        title: Text(route.routeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${route.stops.length} stops • ${route.activeBusIds.length} active buses'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
