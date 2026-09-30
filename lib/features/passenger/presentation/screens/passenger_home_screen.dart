import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/discovery_providers.dart';
import '../../domain/models/home_discovery_data.dart';
import '../../domain/models/bus_stop_info.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showEnableLocationDialog(LocationState locationState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Enable Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Turn on location to find buses near you.\nEasyGo only shows transport options relevant to your current position.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (locationState.permissionStatus ==
                  LocationPermission.deniedForever) {
                Geolocator.openAppSettings();
              } else {
                ref.read(locationProvider.notifier).requestPermission();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(locationState.permissionStatus ==
                    LocationPermission.deniedForever
                ? 'Open Settings'
                : 'Enable Location'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final discoveryAsync = ref.watch(homeDiscoveryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0F172A),
          onRefresh: () async {
            ref.read(locationProvider.notifier).checkPermissionAndFetch();
            ref.invalidate(homeDiscoveryProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              _buildAppBar(locationState),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // 1. Search Destination Box ("Where do you want to go?")
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildTripPlannerShortcut(),
                      const SizedBox(height: 24),

                      // Location check
                      if (!locationState.isLocationEnabled)
                        _buildLocationDisabledState(locationState)
                      else if (locationState.isLoading)
                        _buildLoadingState()
                      else
                        discoveryAsync.when(
                          data: (data) => _buildDiscoveryContent(data),
                          loading: () => _buildLoadingState(),
                          error: (e, _) => _buildErrorState(e.toString()),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(LocationState locationState) {
    final addressText = locationState.isLocationEnabled
        ? (locationState.address ?? 'Locating current position...')
        : 'Location Disabled';

    return SliverAppBar(
      backgroundColor: const Color(0xFF0F172A),
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 90,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Location pulsing pin
              GestureDetector(
                onTap: () {
                  if (!locationState.isLocationEnabled) {
                    _showEnableLocationDialog(locationState);
                  } else {
                    ref
                        .read(locationProvider.notifier)
                        .checkPermissionAndFetch();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: locationState.isLocationEnabled
                        ? const Color(0xFF22C55E).withAlpha(30)
                        : Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Icon(
                        locationState.isLocationEnabled
                            ? Icons.my_location_rounded
                            : Icons.location_disabled_rounded,
                        color: locationState.isLocationEnabled
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'YOUR LOCATION',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (locationState.isLocationEnabled) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE GPS',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      addressText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => context.push('/passenger/notifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => context.push('/passenger/search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Where do you want to go?',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF94A3B8), size: 14),
          ],
        ),
      ),
    );
  }

  // ─── From → To Mode Shortcut ───────────────────────────────────────────────
  Widget _buildTripPlannerShortcut() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/passenger/plan-trip'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alt_route_rounded,
                      color: Color(0xFF4F46E5), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Trip Planner (From → To)',
                    style: TextStyle(
                      color: Color(0xFF4338CA),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Location Disabled State ───────────────────────────────────────────────
  Widget _buildLocationDisabledState(LocationState locationState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_rounded,
                size: 40, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Turn on location to find buses near you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'EasyGo only shows buses and stops relevant to your real location. Turn on GPS to see nearby transport.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showEnableLocationDialog(locationState),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Enable Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading State ─────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF0F172A)),
          SizedBox(height: 16),
          Text(
            'Finding buses near you...',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────────────────
  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Unable to load nearby transport: $message',
        style: const TextStyle(color: Color(0xFFEF4444)),
      ),
    );
  }

  // ─── Location-Aware Discovery Content ──────────────────────────────────────
  Widget _buildDiscoveryContent(HomeDiscoveryData? data) {
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Nearby Buses Section ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Nearby Buses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data.nearbyBuses.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'Within 5 km',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.nearbyBuses.isEmpty)
          _buildEmptyNearbyBusesCard()
        else
          Column(
            children: data.nearbyBuses
                .map((bus) => _buildNearbyBusCard(bus))
                .toList(),
          ),

        const SizedBox(height: 28),

        // ── 2. Nearby Bus Stops & Routes Section ─────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Bus Stops & Routes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (data.nearbyRoutes.isNotEmpty)
              Text(
                'Routes: ${data.nearbyRoutes.map((r) => r.routeNumber).join(", ")}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.nearbyStops.isEmpty)
          _buildEmptyNearbyStopsCard()
        else
          Column(
            children: data.nearbyStops
                .map((stop) => _buildNearbyStopCard(stop))
                .toList(),
          ),
      ],
    );
  }

  // ─── Nearby Bus Card ───────────────────────────────────────────────────────
  Widget _buildNearbyBusCard(NearbyBusItem bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Bus Number Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.directions_bus_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(height: 2),
                    Text(
                      bus.busNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Route & Distance Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bus.origin} → ${bus.destination}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${bus.etaMinutes} min away',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${bus.distanceKm} km',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Live Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next stop: ${bus.nextStop}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    context.push('/passenger/live-tracking/${bus.busId}'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation_rounded,
                          size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Track Bus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Nearby Stop Card ──────────────────────────────────────────────────────
  Widget _buildNearbyStopCard(BusStopInfo stop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pin_drop_rounded,
                    color: Color(0xFF0F172A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stop.address,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context
                    .push('/passenger/stop/${Uri.encodeComponent(stop.name)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('View Buses',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (stop.arrivingBuses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('Next buses: ',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Text(
                      stop.arrivingBuses
                          .map((b) => '${b.busNumber} — ${b.etaMinutes} min')
                          .join('  •  '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyNearbyBusesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'No buses currently running within 5 km of your location.\nUse the search bar above to discover destination routes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildEmptyNearbyStopsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'No bus stops found immediately nearby.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ),
    );
  }
}
