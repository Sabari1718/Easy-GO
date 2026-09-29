import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/providers/location_provider.dart';
import '../../data/services/mock_live_bus_service.dart';

class BusStopDetailsScreen extends ConsumerWidget {
  final String stopName;
  const BusStopDetailsScreen({super.key, required this.stopName});

  static const _stopBuses = <String, List<Map<String, dynamic>>>{
    'Gandhipuram': [
      {'busId': 'bus_12a', 'number': '12A', 'dest': 'Ukkadam', 'eta': 5, 'status': LiveBusStatus.approaching},
      {'busId': 'bus_24', 'number': '24', 'dest': 'Singanallur', 'eta': 9, 'status': LiveBusStatus.onTime},
      {'busId': 'bus_5b', 'number': '5B', 'dest': 'Kovaipudur', 'eta': 14, 'status': LiveBusStatus.delayed},
      {'busId': 'bus_88', 'number': '88', 'dest': 'Tiruppur', 'eta': 18, 'status': LiveBusStatus.onTime},
    ],
    'Town Hall': [
      {'busId': 'bus_12a', 'number': '12A', 'dest': 'Ukkadam', 'eta': 3, 'status': LiveBusStatus.approaching},
      {'busId': 'bus_88', 'number': '88', 'dest': 'Tiruppur', 'eta': 11, 'status': LiveBusStatus.onTime},
    ],
    'RS Puram': [
      {'busId': 'bus_5b', 'number': '5B', 'dest': 'Kovaipudur', 'eta': 7, 'status': LiveBusStatus.delayed},
      {'busId': 'bus_20c', 'number': '20C', 'dest': 'Coimbatore', 'eta': 99, 'status': LiveBusStatus.notRunning},
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final buses = _stopBuses[stopName] ??
        [
          {'busId': 'bus_12a', 'number': '12A', 'dest': 'Ukkadam', 'eta': 5, 'status': LiveBusStatus.onTime},
          {'busId': 'bus_24', 'number': '24', 'dest': 'Singanallur', 'eta': 12, 'status': LiveBusStatus.onTime},
        ];

    // Rough walking distance
    String walkStr = '—';
    if (locationState.currentPosition != null) {
      // Use approximate stop coords
      const stopCoords = {'Gandhipuram': [11.0168, 76.9558], 'Town Hall': [11.0101, 76.9619], 'RS Puram': [11.0080, 76.9480]};
      final coords = stopCoords[stopName] ?? [11.0168, 76.9558];
      final dist = Geolocator.distanceBetween(
        locationState.currentPosition!.latitude,
        locationState.currentPosition!.longitude,
        coords[0], coords[1],
      );
      final walkMin = (dist / 80).ceil(); // ~80m/min walking
      walkStr = '${dist < 1000 ? '${dist.toStringAsFixed(0)}m' : '${(dist / 1000).toStringAsFixed(1)} km'} · ~$walkMin min walk';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0F172A),
              pinned: true,
              expandedHeight: 130,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => context.pop(),
              ),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('BUS STOP',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0)),
                      ),
                      const SizedBox(height: 8),
                      Text(stopName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                      if (walkStr != '—')
                        Text(walkStr,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Next Buses',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    ...buses.map((b) => _buildBusRow(b, context, ref)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusRow(
      Map<String, dynamic> b, BuildContext context, WidgetRef ref) {
    final status = b['status'] as LiveBusStatus;
    final eta = b['eta'] as int;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case LiveBusStatus.onTime:
        statusColor = const Color(0xFF22C55E);
        statusLabel = 'On Time';
        break;
      case LiveBusStatus.delayed:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Delayed';
        break;
      case LiveBusStatus.approaching:
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'Approaching';
        break;
      case LiveBusStatus.notRunning:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Not Running';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: status == LiveBusStatus.notRunning
                  ? const LinearGradient(
                      colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
                  : const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_bus,
                    color: Colors.white, size: 15),
                Text(b['number'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('→ ${b['dest']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status == LiveBusStatus.notRunning
                    ? 'N/A'
                    : '$eta min',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: statusColor),
              ),
              const Text('ETA',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(width: 12),
          if (status != LiveBusStatus.notRunning)
            GestureDetector(
              onTap: () =>
                  context.go('/passenger/live-tracking/${b['busId']}'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Track',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
