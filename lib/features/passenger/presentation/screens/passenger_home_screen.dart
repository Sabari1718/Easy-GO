import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/discovery_providers.dart';
import '../../domain/models/home_discovery_data.dart';
import '../widgets/easygo_hero_header.dart';
import '../widgets/easygo_hero_search.dart';
import '../widgets/easygo_quick_actions.dart';
import '../widgets/easygo_section_header.dart';
import '../widgets/easygo_bus_carousel.dart';
import '../widgets/easygo_trip_planner_card.dart';
import '../widgets/easygo_timeline_stops.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNearby() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        220,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showEnableLocationDialog(LocationState locationState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xFF4F46E5), size: 24),
            SizedBox(width: 8),
            Text(
              'Enable Location',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: const Text(
          'Turn on location to find buses near you.\nEasyGo shows real-time transport options relevant to your current location.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
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
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              locationState.permissionStatus == LocationPermission.deniedForever
                  ? 'Open Settings'
                  : 'Enable Location',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
      body: RefreshIndicator(
        color: const Color(0xFF0F172A),
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.read(locationProvider.notifier).checkPermissionAndFetch();
          ref.invalidate(homeDiscoveryProvider);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Midnight Header + Overlapping Search Card ─────────
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Midnight Navy Hero Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: EasyGoHeroHeader(
                      locationState: locationState,
                      pulseAnimation: _pulseAnimation,
                      onLocationTap: () {
                        if (!locationState.isLocationEnabled) {
                          _showEnableLocationDialog(locationState);
                        } else {
                          ref
                              .read(locationProvider.notifier)
                              .checkPermissionAndFetch();
                        }
                      },
                      onNotificationTap: () =>
                          context.push('/passenger/notifications'),
                      onProfileTap: () => context.push('/passenger/profile'),
                    ),
                  ),

                  // Floating Hero Search Card (overlapping header boundary)
                  const Positioned(
                    left: 20,
                    right: 20,
                    bottom: 0,
                    child: EasyGoHeroSearch(),
                  ),
                ],
              ),

              // ── 2. Primary Body Content ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),

                    // Quick Actions Row (Nearby, Plan Trip, Routes)
                    EasyGoQuickActions(
                      onNearbyTap: _scrollToNearby,
                    ),

                    const SizedBox(height: 24),

                    // Dynamic Discovery / Location Content
                    if (!locationState.isLocationEnabled)
                      _buildLocationDisabledCard(locationState)
                    else if (locationState.isLoading)
                      _buildLoadingSkeleton()
                    else
                      discoveryAsync.when(
                        data: (data) => _buildDiscoveryContent(data, locationState),
                        loading: () => _buildLoadingSkeleton(),
                        error: (e, _) => _buildErrorCard(e.toString()),
                      ),

                    // Extra bottom space so floating navigation pill never obscures content
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Location-Aware Discovery Content ──────────────────────────────────────
  Widget _buildDiscoveryContent(HomeDiscoveryData? data, LocationState locationState) {
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Live Near You (Nearby Buses Section) ──────────────────────────
        EasyGoSectionHeader(
          eyebrow: 'Live Near You',
          title: 'Nearby buses',
          badgeCount: '${data.nearbyBuses.length}',
          actionText: 'View all',
          onActionTap: () => context.push('/passenger/tracking'),
        ),
        const SizedBox(height: 14),

        if (data.nearbyBuses.isEmpty)
          _buildEmptyBusesCard()
        else
          EasyGoBusCarousel(buses: data.nearbyBuses),

        const SizedBox(height: 28),

        // ── 2. Trip Planner Card (From → To) ─────────────────────────────────
        EasyGoTripPlannerCard(
          fromLocation: locationState.address,
        ),

        const SizedBox(height: 28),

        // ── 3. Nearby Stops (Timeline List) ──────────────────────────────────
        EasyGoSectionHeader(
          eyebrow: 'Transit Points',
          title: 'Popular boarding stops',
          badgeCount: '${data.nearbyStops.length}',
          actionText: data.nearbyRoutes.isNotEmpty ? 'See routes' : null,
          onActionTap: data.nearbyRoutes.isNotEmpty
              ? () => context.push('/passenger/routes')
              : null,
        ),
        const SizedBox(height: 14),

        if (data.nearbyStops.isEmpty)
          _buildEmptyStopsCard()
        else
          EasyGoTimelineStops(stops: data.nearbyStops),
      ],
    );
  }

  // ─── Premium Minimal Empty State for Nearby Buses ──────────────────────────
  Widget _buildEmptyBusesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.directions_bus_outlined,
                size: 22,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'NO LIVE BUSES NEARBY',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.1,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nothing is running close to you right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.push('/passenger/search'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Search a destination',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Premium Minimal Empty State for Nearby Stops ──────────────────────────
  Widget _buildEmptyStopsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.pin_drop_outlined,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'NO BUS STOPS NEARBY',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.0,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Boarding stops will appear once you approach a transit route.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Location Disabled State Card ──────────────────────────────────────────
  Widget _buildLocationDisabledCard(LocationState locationState) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.location_off_rounded,
                size: 24,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Location is Disabled',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enable location access to discover buses and transit stops running close to you right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => _showEnableLocationDialog(locationState),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.near_me_rounded, size: 16),
                SizedBox(width: 8),
                Text(
                  'Enable Location',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading State Skeleton ────────────────────────────────────────────────
  Widget _buildLoadingSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: const Center(
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Finding nearby transport...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State Card ──────────────────────────────────────────────────────
  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Could not refresh transit info',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(homeDiscoveryProvider),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
