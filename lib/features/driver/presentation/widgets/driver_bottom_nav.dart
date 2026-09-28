import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverBottomNav extends StatelessWidget {
  final Widget child;
  
  const DriverBottomNav({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/driver/dashboard')) return 0;
    if (location.startsWith('/driver/trip')) return 1;
    if (location.startsWith('/driver/tracking')) return 2;
    if (location.startsWith('/driver/status')) return 3;
    if (location.startsWith('/driver/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/driver/dashboard');
        break;
      case 1:
        context.go('/driver/trip');
        break;
      case 2:
        context.go('/driver/tracking');
        break;
      case 3:
        context.go('/driver/status');
        break;
      case 4:
        context.go('/driver/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Trip'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
