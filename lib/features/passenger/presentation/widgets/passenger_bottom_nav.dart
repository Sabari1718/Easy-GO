import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';

class PassengerBottomNav extends StatelessWidget {
  final Widget child;

  const PassengerBottomNav({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomNavigation(child: child);
  }
}
