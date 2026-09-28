import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/widgets/app_button.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {}, // Placeholder for settings
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('ID: ${user.id}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            _buildProfileItem(Icons.phone, 'Phone', user.phone),
            const Divider(),
            _buildProfileItem(Icons.directions_bus, 'Assigned Bus', user.assignedBusId ?? 'None'),
            const Divider(),
            _buildProfileItem(Icons.route, 'Assigned Route', user.assignedRouteId ?? 'None'),
            const SizedBox(height: 48),
            AppButton(
              text: 'Logout',
              isSecondary: true,
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
