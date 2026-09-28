import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/bus_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';

class BusDetailsScreen extends ConsumerWidget {
  final String busId;

  const BusDetailsScreen({super.key, required this.busId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busAsync = ref.watch(selectedBusProvider(busId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bus Details')),
      body: busAsync.when(
        data: (bus) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(bus.busNumber, style: Theme.of(context).textTheme.headlineMedium),
                          StatusChip(status: bus.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildDetailRow('Route', bus.routeId),
                      const SizedBox(height: 12),
                      _buildDetailRow('Next Stop', 'Town Hall'), // Hardcoded for mock
                      const SizedBox(height: 12),
                      _buildDetailRow('ETA', '${bus.etaMinutes} mins'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Capacity', bus.status.name.toUpperCase()),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Track Live',
                  onPressed: () {
                    context.push('/passenger/tracking');
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
