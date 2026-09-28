import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigation extends StatelessWidget {
  final Widget child;

  const CustomBottomNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    
    int currentIndex = 0;
    if (location.startsWith('/passenger/home')) currentIndex = 0;
    if (location.startsWith('/passenger/activity')) currentIndex = 1; // Assuming these exist, we'll route appropriately
    if (location.startsWith('/passenger/services')) currentIndex = 2;
    if (location.startsWith('/passenger/profile')) currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: () => context.go('/passenger/home'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.history_rounded,
                  label: 'Activity',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: () {
                    // Navigate to activity (mock)
                  },
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  label: 'Services',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: () {
                    // Navigate to services (mock)
                  },
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: () => context.go('/passenger/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20.0 : 12.0,
          vertical: 12.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
