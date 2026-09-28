import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/trip_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/models/trip_model.dart';

class DriverCurrentTripScreen extends ConsumerWidget {
  const DriverCurrentTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTripAsync = ref.watch(currentTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Trip'),
      ),
      body: currentTripAsync.when(
        data: (trip) {
          if (trip == null || trip.status != TripStatus.active) {
            return const EmptyStateWidget(
              message: 'No active trip.\nStart a trip from the Dashboard.',
              icon: Icons.directions_bus,
            );
          }
          return _buildActiveTrip(context, ref, trip);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildActiveTrip(BuildContext context, WidgetRef ref, TripModel trip) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Route: ${trip.routeId}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Bus: ${trip.busId}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(
              child: Text('Map Placeholder\n(See Tracking tab for map)'),
            ),
          ),
          AppButton(
            text: 'End Trip',
            isSecondary: true,
            onPressed: () {
              _showEndTripDialog(context, ref, trip.id);
            },
          ),
        ],
      ),
    );
  }

  void _showEndTripDialog(BuildContext context, WidgetRef ref, String tripId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Trip'),
        content: const Text('Are you sure you want to end the current trip? Location sharing will stop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(tripControllerProvider.notifier).endTrip(tripId);
              context.go('/driver/dashboard');
            },
            child: const Text('End Trip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
