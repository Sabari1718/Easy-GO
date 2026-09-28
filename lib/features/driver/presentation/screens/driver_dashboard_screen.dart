import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/trip_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/trip_model.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentTripAsync = ref.watch(currentTripProvider);

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
      ),
      body: currentTripAsync.when(
        data: (trip) => _buildDashboard(context, ref, user.name, user.assignedBusId, user.assignedRouteId, trip),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, String driverName, String? busId, String? routeId, TripModel? trip) {
    final isTripActive = trip != null && trip.status == TripStatus.active;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome, $driverName',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assignment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow('Assigned Bus', busId ?? 'None'),
                const SizedBox(height: 8),
                _buildInfoRow('Assigned Route', routeId ?? 'None'),
                const SizedBox(height: 8),
                _buildInfoRow('Status', isTripActive ? 'Trip Active' : 'Ready to Start'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!isTripActive && busId != null && routeId != null)
            AppButton(
              text: 'Start Trip',
              onPressed: () {
                _showStartTripDialog(context, ref, busId, routeId);
              },
            )
          else if (isTripActive)
            AppButton(
              text: 'View Current Trip',
              onPressed: () {
                context.go('/driver/trip');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showStartTripDialog(BuildContext context, WidgetRef ref, String busId, String routeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Trip'),
        content: const Text('Are you sure you want to start the trip? Location sharing will be active.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(tripControllerProvider.notifier).startTrip(busId, routeId);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
