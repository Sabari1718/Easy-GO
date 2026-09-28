import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/location_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Premium Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(50), width: 2),
                      image: const DecorationImage(
                        image: NetworkImage('https://ui-avatars.com/api/?name=User&background=fff&color=0F172A'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EasyGo User',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+91 ${user?.phone ?? "XXXXXXXXXX"}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withAlpha(180),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Sections
            _buildSectionHeader('PREFERENCES'),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 64),
                  _buildLocationTile(context, ref, locationState),
                  const Divider(height: 1, indent: 64),
                  _buildSettingsTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'App Theme',
                    subtitle: 'Light',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            _buildSectionHeader('SUPPORT'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(icon: Icons.help_rounded, title: 'Help & Support', onTap: () {}),
                  const Divider(height: 1, indent: 64),
                  _buildSettingsTile(icon: Icons.info_rounded, title: 'About EasyGo', onTap: () {}),
                  const Divider(height: 1, indent: 64),
                  _buildSettingsTile(icon: Icons.privacy_tip_rounded, title: 'Privacy Policy', onTap: () {}),
                  const Divider(height: 1, indent: 64),
                  _buildSettingsTile(icon: Icons.description_rounded, title: 'Terms & Conditions', onTap: () {}),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader('ACCOUNT'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: _buildSettingsTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                titleColor: const Color(0xFFEF4444),
                iconColor: const Color(0xFFEF4444),
                showArrow: false,
                onTap: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = const Color(0xFF0F172A),
    Color iconColor = const Color(0xFF64748B),
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(BuildContext context, WidgetRef ref, LocationState state) {
    final bool isEnabled = state.isLocationEnabled;
    final bool isDeniedForever = state.permissionStatus == LocationPermission.deniedForever;

    return InkWell(
      onTap: () {
        if (!isEnabled) {
          if (isDeniedForever) {
            Geolocator.openAppSettings();
          } else {
            ref.read(locationProvider.notifier).requestPermission();
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEnabled ? const Color(0xFF22C55E).withAlpha(20) : const Color(0xFFEF4444).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded, 
                color: isEnabled ? const Color(0xFF22C55E) : const Color(0xFFEF4444), 
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEnabled ? 'Location access is enabled' : 'Location access is disabled',
                    style: TextStyle(
                      fontSize: 13,
                      color: isEnabled ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isEnabled)
              TextButton(
                onPressed: () {
                  if (isDeniedForever) {
                    Geolocator.openAppSettings();
                  } else {
                    ref.read(locationProvider.notifier).requestPermission();
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  isDeniedForever ? 'Settings' : 'Enable',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
