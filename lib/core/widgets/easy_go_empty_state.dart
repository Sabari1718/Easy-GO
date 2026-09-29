import 'package:flutter/material.dart';
import 'easy_go_button.dart';

class EasyGoEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onAction;
  final IconData icon;

  const EasyGoEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onAction,
    this.icon = Icons.directions_bus_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF6366F1)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: EasyGoButton(
                text: buttonText,
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
