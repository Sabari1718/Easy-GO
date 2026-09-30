import 'package:flutter/material.dart';
import '../../domain/models/home_discovery_data.dart';
import 'easygo_bus_card.dart';

class EasyGoBusCarousel extends StatelessWidget {
  final List<NearbyBusItem> buses;

  const EasyGoBusCarousel({super.key, required this.buses});

  @override
  Widget build(BuildContext context) {
    if (buses.isEmpty) return const SizedBox.shrink();

    // If only 1 bus, render full width
    if (buses.length == 1) {
      return EasyGoBusCard(bus: buses.first);
    }

    // Carousel with responsive width cards
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.82).clamp(280.0, 340.0);

    return SizedBox(
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: buses.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final bus = buses[index];
          return EasyGoBusCard(
            bus: bus,
            width: cardWidth,
          );
        },
      ),
    );
  }
}
