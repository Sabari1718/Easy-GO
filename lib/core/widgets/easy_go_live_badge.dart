import 'package:flutter/material.dart';

class EasyGoLiveBadge extends StatefulWidget {
  final String label;
  final Color color;
  final bool pulse;

  const EasyGoLiveBadge({
    super.key,
    this.label = 'LIVE',
    this.color = const Color(0xFF22C55E),
    this.pulse = true,
  });

  @override
  State<EasyGoLiveBadge> createState() => _EasyGoLiveBadgeState();
}

class _EasyGoLiveBadgeState extends State<EasyGoLiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withAlpha(50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pulse)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.color.withAlpha((_animation.value * 255).toInt()),
                  shape: BoxShape.circle,
                ),
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
