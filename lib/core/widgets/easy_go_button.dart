import 'package:flutter/material.dart';

class EasyGoButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const EasyGoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.height = 54,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (isPrimary ? const Color(0xFF0F172A) : Colors.white);
    final fg = textColor ?? (isPrimary ? Colors.white : const Color(0xFF0F172A));

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? const Color(0xFF0F172A).withAlpha(40) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: fg,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
