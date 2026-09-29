import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/live_tracking_providers.dart';
import '../../domain/models/bus_live_state.dart';
import '../../data/repositories/mock_live_bus_tracking_repository.dart';
import '../../data/services/mock_live_bus_service.dart';

/// The "Live" tab — shows all active buses on a map + a list
class PassengerTrackingScreen extends ConsumerStatefulWidget {
  const PassengerTrackingScreen({super.key});

  @override
  ConsumerState<PassengerTrackingScreen> createState() =>
      _PassengerTrackingScreenState();
}

class _PassengerTrackingScreenState
    extends ConsumerState<PassengerTrackingScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final bus12aStateAsync = ref.watch(busLiveStateStreamProvider('bus_12a'));
    final service = ref.read(mockLiveBusServiceProvider);
    final allBuses = service.allBuses;

    final bus12a = bus12aStateAsync.value;
    final userPos = locationState.currentPosition;
    final initialTarget = bus12a != null
        ? LatLng(bus12a.latitude, bus12a.longitude)
        : (userPos != null
            ? LatLng(userPos.latitude, userPos.longitude)
            : const LatLng(10.9572, 76.9485));

    final Set<Marker> mapMarkers = {};
    final Set<Polyline> mapPolylines = {};

    if (bus12a != null) {
      mapMarkers.add(
        Marker(
          markerId: const MarkerId('bus_12a_live'),
          position: LatLng(bus12a.latitude, bus12a.longitude),
          rotation: bus12a.heading,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: 'Bus 12A (${bus12a.status.label})',
            snippet: 'Next: ${bus12a.nextStopName} • ETA ${bus12a.etaMinutes}m',
          ),
        ),
      );

      // Add polyline for Ukkadam -> Pollachi
      mapPolylines.add(
        Polyline(
          polylineId: const PolylineId('route_12a'),
          points: MockLiveBusTrackingRepository.ukkadamPollachiPolyline
              .map((p) => LatLng(p.lat, p.lng))
              .toList(),
          color: const Color(0xFF6366F1),
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Map
            SizedBox(
              height: 260,
              child: Stack(
                children: [
                  ClipRRect(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialTarget,
                        zoom: 12.5,
                      ),
                      onMapCreated: (c) {
                        _mapController = c;
                      },
                      markers: mapMarkers,
                      polylines: mapPolylines,
                      myLocationEnabled: locationState.isLocationEnabled,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                  ),
                  // Recenter button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        if (userPos != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(LatLng(
                                userPos.latitude, userPos.longitude)),
                          );
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: Color(0xFF6366F1), size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bus list
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Live Buses Near You',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF22C55E).withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                const Text('Live',
                                    style: TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final info = allBuses[index];
                          return _buildLiveBusListItem(info, index);
                        },
                        childCount: allBuses.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Tracking',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
              Text(
                'Real-time bus locations',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('Live',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBusListItem(LiveBusInfo info, int index) {
    if (info.busId == 'bus_12a') {
      final busStateAsync = ref.watch(busLiveStateStreamProvider('bus_12a'));
      final state = busStateAsync.value;
      if (state != null) {
        return _buildBus12ACard(info, state);
      }
    }

    return StreamBuilder<LiveBusLocation>(
      stream:
          ref.read(mockLiveBusServiceProvider).getLiveBusStream(info.busId),
      builder: (context, snapshot) {
        final loc = snapshot.data;
        final eta = loc?.etaMinutes ?? (3 + index * 4);
        final status = loc?.status ?? LiveBusStatus.onTime;
        final nextStop = loc?.nextStop ?? info.allStops[1].name;

        Color statusColor;
        switch (status) {
          case LiveBusStatus.onTime:
            statusColor = const Color(0xFF22C55E);
            break;
          case LiveBusStatus.delayed:
            statusColor = const Color(0xFFF59E0B);
            break;
          case LiveBusStatus.approaching:
            statusColor = const Color(0xFF3B82F6);
            break;
          case LiveBusStatus.notRunning:
            statusColor = const Color(0xFFEF4444);
            break;
        }

        return GestureDetector(
          onTap: () =>
              context.go('/passenger/live-tracking/${info.busId}'),
          child: Container(
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: status == LiveBusStatus.notRunning
                          ? [
                              const Color(0xFF94A3B8),
                              const Color(0xFF64748B)
                            ]
                          : [
                              const Color(0xFF0F172A),
                              const Color(0xFF1E3A5F)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bus,
                          color: Colors.white, size: 16),
                      Text(
                        info.busNumber,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${info.origin} → ${info.destination}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Next: $nextStop',
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 12)),
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
                          fontSize: 18,
                          color: statusColor),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBus12ACard(LiveBusInfo info, BusLiveState state) {
    final statusColor = state.status.color;
    final statusLabel = state.status.label;

    return GestureDetector(
      onTap: () => context.go('/passenger/live-tracking/bus_12a'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF6366F1).withAlpha(60), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, color: Colors.white, size: 16),
                  Text(
                    '12A',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Ukkadam → Pollachi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE SIM',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.status == BusJourneyStatus.stoppedAtStop
                        ? 'At Stop: ${state.currentStopName}'
                        : 'Next: ${state.nextStopName} (${state.distanceToNextStop.toStringAsFixed(1)} km)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${state.etaMinutes} min',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: statusColor),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }
}
