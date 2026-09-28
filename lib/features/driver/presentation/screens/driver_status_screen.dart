import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/bus_providers.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../buses/domain/models/bus_model.dart';

class DriverStatusScreen extends ConsumerWidget {
  const DriverStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    if (user?.assignedBusId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bus Status')),
        body: const Center(child: Text('No bus assigned.')),
      );
    }

    final busAsync = ref.watch(selectedBusProvider(user!.assignedBusId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Status'),
      ),
      body: busAsync.when(
        data: (bus) => _buildStatusOptions(context, ref, bus),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatusOptions(BuildContext context, WidgetRef ref, BusModel bus) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Current Status: ${bus.status.name.toUpperCase()}',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildStatusCard(
          context: context,
          title: 'FULL',
          icon: Icons.group_off,
          color: Colors.red,
          onTap: () => _updateStatus(context, ref, bus.id, BusStatus.full),
        ),
        _buildStatusCard(
          context: context,
          title: 'NOT FULL',
          icon: Icons.group,
          color: Colors.green,
          onTap: () => _updateStatus(context, ref, bus.id, BusStatus.notFull),
        ),
        _buildStatusCard(
          context: context,
          title: 'BREAKDOWN REQUEST',
          icon: Icons.build,
          color: Colors.orange,
          onTap: () => _updateStatus(context, ref, bus.id, BusStatus.breakdown),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(width: 24),
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String busId, BusStatus status) {
    String message = 'Are you sure you want to change status to ${status.name.toUpperCase()}?';
    if (status == BusStatus.breakdown) {
      message = 'Are you sure you want to send a breakdown request?';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(updateBusStatusProvider((busId: busId, status: status)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(status == BusStatus.breakdown ? 'Breakdown request sent' : 'Status updated')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
