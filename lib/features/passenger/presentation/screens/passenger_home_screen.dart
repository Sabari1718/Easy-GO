import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/live_tracking_providers.dart';
import '../../domain/models/bus_live_state.dart';
import '../../domain/models/bus_stop_info.dart';
import '../../data/services/mock_live_bus_service.dart';
import '../../data/repositories/mock_bus_stop_repository.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState
    extends ConsumerState<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  bool _hasPromptedLocation = false;
  final _storage = const FlutterSecureStorage();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initPromptFlag();
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

  Future<void> _initPromptFlag() async {
    final prompted = await _storage.read(key: 'has_prompted_location');
    if (mounted) setState(() => _hasPromptedLocation = prompted == 'true');
  }

  void _showLocationPermissionPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Turn On Location',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Enable your location to find buses near you and show your current location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Not Now', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(locationProvider.notifier).requestPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  void _showLocationBottomSheet(
      BuildContext context, LocationState locationState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Location',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationState.isLocationEnabled
                            ? (locationState.address ?? 'Locating...')
                            : 'Location Disabled',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                      if (locationState.isLocationEnabled)
                        const Text('Tamil Nadu, India',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (!locationState.isLocationEnabled) {
                    ref.read(locationProvider.notifier).requestPermission();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  locationState.isLocationEnabled
                      ? 'Change Location'
                      : 'Enable Location',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    ref.listen<LocationState>(locationProvider, (previous, next) async {
      if (next.isPermissionChecked && !next.isLocationEnabled) {
        if (!_hasPromptedLocation &&
            next.permissionStatus != LocationPermission.deniedForever) {
          _hasPromptedLocation = true;
          await _storage.write(
              key: 'has_prompted_location', value: 'true');
          if (mounted) _showLocationPermissionPrompt();
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(locationState),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(locationState),
                  _buildSearchBar(),
                  _buildQuickActions(),
                  _buildWhereIsMyBusCard(),
                  _buildNearbyBuses(locationState),
                  _buildNearbyStops(),
                  _buildPopularRoutes(),
                  _buildAlerts(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(LocationState locationState) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      toolbarHeight: 100,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF0F172A)
            ],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            )
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      title: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showLocationBottomSheet(context, locationState),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                locationState.isLocationEnabled
                                    ? (locationState.address ?? 'Locating...')
                                    : 'Location Disabled',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: Colors.white70),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/passenger/notifications'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/passenger/profile'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                border: Border.all(color: Colors.white.withAlpha(50), width: 2),
              ),
              child: const Center(
                child: Text('U',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(LocationState locationState) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning ☀️'
        : hour < 17
            ? 'Good Afternoon 🌤️'
            : 'Good Evening 🌙';

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 24.0).copyWith(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Where do you want to go today?',
            style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 24.0).copyWith(top: 16),
      child: GestureDetector(
        onTap: () => context.push('/passenger/search'),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: const Row(
            children: [
              SizedBox(width: 16),
              Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search bus, stop or destination...',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text(
                  'Search',
                  style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.directions_bus_rounded, 'label': 'Live Bus', 'color': const Color(0xFF6366F1), 'route': '/passenger/tracking'},
      {'icon': Icons.route_rounded, 'label': 'Routes', 'color': const Color(0xFF10B981), 'route': '/passenger/routes'},
      {'icon': Icons.map_rounded, 'label': 'Plan Trip', 'color': const Color(0xFFF59E0B), 'route': '/passenger/plan-trip'},
      {'icon': Icons.favorite_rounded, 'label': 'Saved', 'color': const Color(0xFFEF4444), 'route': '/passenger/saved'},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions
            .map((a) => _buildQuickAction(
                  icon: a['icon'] as IconData,
                  label: a['label'] as String,
                  color: a['color'] as Color,
                  route: a['route'] as String,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withAlpha(40), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildWhereIsMyBusCard() {
    final liveStateAsync = ref.watch(busLiveStateStreamProvider('bus_12a'));
    final state = liveStateAsync.value;

    final currentNear = state != null
        ? (state.status == BusJourneyStatus.stoppedAtStop
            ? 'Stopped at ${state.currentStopName}'
            : 'Currently near ${state.currentStopName}')
        : 'Currently near Madukkarai';
    final nextStop = state?.nextStopName ?? 'Ettimadai';
    final eta = state?.etaMinutes ?? 7;
    final statusColor = state?.status.color ?? const Color(0xFF22C55E);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
            color: const Color(0xFF6366F1).withAlpha(60), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.radar_rounded,
                        color: Color(0xFF818CF8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'WHERE IS MY BUS?',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state?.status.label ?? 'Live',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_bus_rounded,
                        color: Colors.white, size: 16),
                    Text(
                      '12A',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ukkadam → Pollachi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your bus is $currentNear',
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF94A3B8), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Next stop: $nextStop',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  'Arriving in: $eta min',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/passenger/live-tracking/bus_12a'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text(
                'Track Live',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyBuses(LocationState locationState) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Buses',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              GestureDetector(
                onTap: () => context.go('/passenger/tracking'),
                child: const Text('View All →',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!locationState.isLocationEnabled)
            _buildLocationDisabledCard(locationState)
          else if (locationState.isLoading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF0F172A)),
            ))
          else
            _buildLiveBusList(locationState.currentPosition),
        ],
      ),
    );
  }

  Widget _buildLocationDisabledCard(LocationState locationState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.location_disabled_rounded,
              size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text('Turn on location to discover buses near you',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            child: Text(
                locationState.permissionStatus ==
                        LocationPermission.deniedForever
                    ? 'Open Settings'
                    : 'Enable Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBusList(Position? userPos) {
    final service = ref.read(mockLiveBusServiceProvider);
    final allBuses = service.allBuses;
    final favorites = ref.watch(favoritesProvider);

    // Show all buses with mock distance computed from user pos
    final busesWithDist = allBuses.map((b) {
      double distKm = 0.8 + allBuses.indexOf(b) * 0.6;
      if (userPos != null) {
        final idx = 0;
        final pt = b.routePolyline[idx];
        distKm = Geolocator.distanceBetween(
                userPos.latitude, userPos.longitude, pt.lat, pt.lng) /
            1000;
      }
      return {'info': b, 'distKm': distKm};
    }).toList();

    busesWithDist
        .sort((a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double));

    return Column(
      children: busesWithDist.map((entry) {
        final info = entry['info'] as LiveBusInfo;
        final distKm = entry['distKm'] as double;
        final isFav = favorites.contains(info.busId);
        return _buildLiveBusCard(info, distKm, isFav);
      }).toList(),
    );
  }

  Widget _buildLiveBusCard(LiveBusInfo info, double distKm, bool isFav) {
    return StreamBuilder<LiveBusLocation>(
      stream: ref.read(mockLiveBusServiceProvider).getLiveBusStream(info.busId),
      builder: (context, snapshot) {
        final loc = snapshot.data;
        final status = loc?.status ?? LiveBusStatus.onTime;
        final etaMin = loc?.etaMinutes ?? 5;
        final stopsAway = loc?.stopsAway ?? 2;
        final speed = loc?.speedKmh ?? 28;

        Color statusColor;
        String statusLabel;
        switch (status) {
          case LiveBusStatus.onTime:
            statusColor = const Color(0xFF22C55E);
            statusLabel = '🟢 On Time';
            break;
          case LiveBusStatus.delayed:
            statusColor = const Color(0xFFF59E0B);
            statusLabel = '🟡 Delayed';
            break;
          case LiveBusStatus.approaching:
            statusColor = const Color(0xFF3B82F6);
            statusLabel = '🔵 Approaching';
            break;
          case LiveBusStatus.notRunning:
            statusColor = const Color(0xFFEF4444);
            statusLabel = '🔴 Not Running';
            break;
        }

        return GestureDetector(
          onTap: () {
            _showBusDetailSheet(context, info, loc, distKm);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Bus number badge
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: status == LiveBusStatus.notRunning
                                ? [
                                    const Color(0xFF94A3B8),
                                    const Color(0xFF64748B)
                                  ]
                                : [
                                    const Color(0xFF0F172A),
                                    const Color(0xFF1E293B)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_bus,
                                color: Colors.white, size: 18),
                            const SizedBox(height: 2),
                            Text(
                              info.busNumber,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${info.origin} → ${info.destination}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A)),
                                  ),
                                ),
                                // Favorite button
                                GestureDetector(
                                  onTap: () => ref
                                      .read(favoritesProvider.notifier)
                                      .toggle(info.busId),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF94A3B8),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Live indicator
                                if (status != LiveBusStatus.notRunning)
                                  ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                          color: Color(0xFF22C55E),
                                          shape: BoxShape.circle),
                                    ),
                                  ),
                                if (status != LiveBusStatus.notRunning)
                                  const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${distKm.toStringAsFixed(1)} km away',
                                  style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom info bar
                if (status != LiveBusStatus.notRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(
                            Icons.access_time_rounded,
                            'Arriving in $etaMin min',
                            const Color(0xFF6366F1)),
                        _buildInfoChip(
                            Icons.stop_circle_outlined,
                            '$stopsAway stops away',
                            const Color(0xFF10B981)),
                        _buildInfoChip(
                            Icons.speed_rounded,
                            '${speed.toStringAsFixed(0)} km/h',
                            const Color(0xFFF59E0B)),
                        // Track button
                        GestureDetector(
                          onTap: () => context.go(
                              '/passenger/live-tracking/${info.busId}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
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
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showBusDetailSheet(BuildContext context, LiveBusInfo info,
      LiveBusLocation? loc, double distKm) {
    final status = loc?.status ?? LiveBusStatus.onTime;
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bus,
                          color: Colors.white, size: 22),
                      Text(info.busNumber,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${info.origin} → ${info.destination}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '● ${status.label}',
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
            const SizedBox(height: 20),
            // Info grid
            Row(
              children: [
                Expanded(
                    child: _buildDetailTile('Next Stop',
                        loc?.nextStop ?? 'Town Hall', Icons.stop_circle)),
                Expanded(
                    child: _buildDetailTile(
                        'Arriving',
                        '${loc?.etaMinutes ?? 5} min',
                        Icons.access_time_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildDetailTile('Distance',
                        '${distKm.toStringAsFixed(1)} km', Icons.near_me)),
                Expanded(
                    child: _buildDetailTile(
                        'Speed',
                        '${(loc?.speedKmh ?? 28).toStringAsFixed(0)} km/h',
                        Icons.speed_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/passenger/routes');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F172A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('View Route',
                        style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/passenger/live-tracking/${info.busId}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Track Live',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildNearbyStops() {
    final locationState = ref.watch(locationProvider);
    final userPos = locationState.currentPosition;
    final allStopsFuture = MockBusStopRepository().getNearbyStops(userPos);

    return Padding(
      padding: const EdgeInsets.only(top: 28, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nearby Stops',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              GestureDetector(
                onTap: () => context.go('/passenger/routes'),
                child: const Text('View All →',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<BusStopInfo>>(
            future: allStopsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ));
              }
              final stops = snapshot.data!;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: stops.asMap().entries.map((entry) {
                    final i = entry.key;
                    final stop = entry.value;
                    double distMeters = 350.0 + i * 150;
                    if (userPos != null) {
                      distMeters = Geolocator.distanceBetween(
                        userPos.latitude, userPos.longitude,
                        stop.latitude, stop.longitude,
                      );
                    }
                    final walkMin = (distMeters / 80).ceil();
                    final distStr = distMeters < 1000
                        ? '${distMeters.toStringAsFixed(0)} m'
                        : '${(distMeters / 1000).toStringAsFixed(1)} km';

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => context.push(
                              '/passenger/stop/${Uri.encodeComponent(stop.name)}'),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFF6366F1).withAlpha(15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.location_on_rounded,
                                      color: Color(0xFF6366F1), size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stop.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text('Walk: ~$walkMin min',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0EA5E9))),
                                          const SizedBox(width: 8),
                                          ...stop.arrivingBuses.take(2).map((b) => Container(
                                                margin: const EdgeInsets
                                                    .only(right: 6),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                          0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6),
                                                ),
                                                child: Text('${b.busNumber} (${b.etaMinutes}m)',
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                            0xFF475569))),
                                              )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      distStr,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                          fontSize: 13),
                                    ),
                                    const Text('away',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (i < stops.length - 1)
                          const Divider(
                              height: 1,
                              indent: 58,
                              color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopularRoutes() {
    final routes = [
      {'number': '12A', 'origin': 'Gandhipuram', 'dest': 'Ukkadam', 'id': 'r12a'},
      {'number': '24', 'origin': 'Gandhipuram', 'dest': 'Singanallur', 'id': 'r24'},
      {'number': '5B', 'origin': 'RS Puram', 'dest': 'Kovaipudur', 'id': 'r5b'},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 28, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Popular Routes',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              GestureDetector(
                onTap: () => context.go('/passenger/routes'),
                child: const Text('View All →',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: routes.length,
              itemBuilder: (context, i) {
                final r = routes[i];
                return GestureDetector(
                  onTap: () =>
                      context.go('/passenger/route/${r['id']}'),
                  child: Container(
                    width: 180,
                    margin: EdgeInsets.only(right: i < routes.length - 1 ? 12 : 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F172A),
                          const Color(0xFF1E3A5F),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r['number']!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r['origin']}',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11)),
                            const Icon(Icons.arrow_downward,
                                color: Colors.white70, size: 12),
                            Text('${r['dest']}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts() {
    final alerts = [
      {
        'icon': '⚠️',
        'bus': '12A',
        'msg': 'Traffic delay near Town Hall',
        'color': const Color(0xFFFEF3C7),
        'border': const Color(0xFFF59E0B),
      },
      {
        'icon': '🚌',
        'bus': '24',
        'msg': 'Bus approaching your stop in 2 min',
        'color': const Color(0xFFEFF6FF),
        'border': const Color(0xFF3B82F6),
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 28, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alerts',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          ...alerts.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: a['color'] as Color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (a['border'] as Color).withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Text(a['icon'] as String,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bus ${a['bus']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                          Text(a['msg'] as String,
                              style: const TextStyle(
                                  color: Color(0xFF475569), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
