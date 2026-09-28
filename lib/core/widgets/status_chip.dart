import 'package:flutter/material.dart';
import '../../features/buses/domain/models/bus_model.dart';
import '../constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final BusStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case BusStatus.onRoute:
        color = AppColors.busOnRoute;
        text = 'On Route';
        break;
      case BusStatus.full:
        color = AppColors.busFull;
        text = 'Full';
        break;
      case BusStatus.notFull:
        color = AppColors.busNotFull;
        text = 'Not Full';
        break;
      case BusStatus.breakdown:
        color = AppColors.warning;
        text = 'Breakdown';
        break;
      case BusStatus.offline:
        color = Colors.grey;
        text = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
