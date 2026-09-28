import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/widgets/app_button.dart';

class PassengerProfileScreen extends ConsumerWidget {
  const PassengerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
            Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            _buildSettingsItem(Icons.notifications, 'Notifications', true),
            const Divider(),
            _buildSettingsItem(Icons.location_on, 'Location Access', true),
            const Divider(),
            _buildSettingsItem(Icons.dark_mode, 'Dark Theme', false),
            const Divider(),
            _buildSettingsItem(Icons.language, 'Language', 'English'),
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
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                context.push('/driver-login');
              },
              child: const Text('Driver Access Portal', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, dynamic value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: value is bool
          ? Switch(value: value, onChanged: (_) {})
          : Text(value.toString(), style: const TextStyle(color: Colors.grey)),
    );
  }
}
