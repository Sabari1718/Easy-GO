import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/live_tracking_providers.dart';
import '../../data/repositories/mock_live_bus_tracking_repository.dart';
import '../../domain/models/bus_live_state.dart';
import '../../domain/repositories/live_bus_tracking_repository.dart';
import '../../data/services/mock_live_bus_service.dart';

// ─── Precomputed static polyline points (computed once, never recreated) ──────
final List<LatLng> _staticPolylinePoints = MockLiveBusTrackingRepository
    .ukkadamPollachiPolyline
    .map((p) => LatLng(p.lat, p.lng))
    .toList(growable: false);

// ─── Main Screen ─────────────────────────────────────────────────────────────

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String busId;
  const LiveTrackingScreen({super.key, required this.busId});

  @override
  ConsumerState<LiveTrackingScreen> createState() =>
      _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen>
    with TickerProviderStateMixin {
  bool _followBus = true;
  bool _showDetailsPanel = true;
  bool _showDevControls = false;

  // Smooth marker interpolation — driven by Ticker, NOT by setState
  LatLng? _previousLatLng;
  LatLng? _targetLatLng;
  LatLng _animatedLatLng = const LatLng(10.9902, 76.9607);

  late AnimationController _animController;
  Animation<double>? _anim;

  // Map controller is owned by _LiveMapWidget; we store a reference here
  // via a callback so the parent can still trigger camera moves.
  GoogleMapController? _mapController;

  void _onMapControllerReady(GoogleMapController ctrl) {
    _mapController = ctrl;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Called when a new bus position arrives (NOT inside build) ──────────────
  void _onBusPositionUpdate(LatLng newPos) {
    if (_targetLatLng == null) {
      _targetLatLng = newPos;
      _animatedLatLng = newPos;
      return;
    }

    // Skip animation if the difference is negligible (< ~1 meter)
    final latDiff = (newPos.latitude - _targetLatLng!.latitude).abs();
    final lngDiff = (newPos.longitude - _targetLatLng!.longitude).abs();
    if (latDiff < 0.000009 && lngDiff < 0.000009) {
      return;
    }

    _previousLatLng = _animatedLatLng;
    _targetLatLng = newPos;

    _animController.reset();
    final prevLat = _previousLatLng!.latitude;
    final prevLng = _previousLatLng!.longitude;
    final targLat = newPos.latitude;
    final targLng = newPos.longitude;

    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    )..addListener(() {
        final t = _anim?.value ?? 1.0;
        _animatedLatLng = LatLng(
          prevLat + (targLat - prevLat) * t,
          prevLng + (targLng - prevLng) * t,
        );
        // Notify the _LiveMapWidget via its key directly without calling setState
        // on the parent. The map widget has its own _animatedLatLng reference.
        _mapWidgetKey.currentState?.updateAnimatedPosition(_animatedLatLng);
      });
    _animController.forward();
  }

  void _fitRouteBounds() {
    if (_mapController == null) return;
    const minLat = 10.6588;
    const maxLat = 10.9902;
    const minLng = 76.9030;
    const maxLng = 77.0220;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: const LatLng(minLat, minLng),
          northeast: const LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  void _recenterBus(LatLng busPos, double heading) {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: busPos,
          zoom: 15.5,
          bearing: heading,
          tilt: 35.0,
        ),
      ),
    );
  }

  // Key so parent can call methods on _LiveMapWidget state
  final GlobalKey<_LiveMapWidgetState> _mapWidgetKey =
      GlobalKey<_LiveMapWidgetState>();

  @override
  Widget build(BuildContext context) {
    // Watch only what the AppBar and outer panels need.
    // We do NOT watch locationProvider here — the map uses myLocationEnabled
    // built-in and we only need userPos for the recenter button (read-only).
    final isFav = ref.watch(favoritesProvider).contains(widget.busId);
    final busStateAsync = ref.watch(busLiveStateStreamProvider(widget.busId));
    final repo = ref.read(liveBusTrackingRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isFav, busStateAsync.value),
      body: busStateAsync.when(
        data: (busState) {
          final busPos = LatLng(busState.latitude, busState.longitude);

          // Side-effect: update animation. We use addPostFrameCallback so this
          // never runs inside a build phase and never triggers cascading rebuilds.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _onBusPositionUpdate(busPos);
            if (_followBus && _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _animatedLatLng,
                    zoom: 15.5,
                    bearing: busState.heading,
                    tilt: 30.0,
                  ),
                ),
              );
            }
          });

          return Stack(
            children: [
              // 1. Google Map — isolated widget that controls its own rebuilds
              _LiveMapWidget(
                key: _mapWidgetKey,
                busId: widget.busId,
                busState: busState,
                initialPos: _animatedLatLng,
                onMapReady: _onMapControllerReady,
                onUserPan: () {
                  if (_followBus) setState(() => _followBus = false);
                },
                repo: repo,
              ),

              // 2. Top Live Status Header & "Is My Bus Coming?" Banner
              SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopStatusBar(busState),
                    _buildIsMyBusComingBanner(busState),
                    if (busState.selectedStopId != null)
                      _buildPassengerSelectedStopBanner(busState, repo),
                  ],
                ),
              ),

              // 3. Right Floating Map Controls
              _buildFloatingMapControls(busPos, busState.heading),

              // 4. Developer Simulation Floating Controls (if toggled)
              if (_showDevControls) _buildDevControlsPanel(busState, repo),

              // 5. Journey Completed Overlay
              if (busState.status == BusJourneyStatus.serviceEnded)
                _buildJourneyCompletedOverlay(busState, repo),

              // 6. Sliding Bottom Details Panel
              if (_showDetailsPanel &&
                  busState.status != BusJourneyStatus.serviceEnded)
                _buildBottomDetailsPanel(busState, repo),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Live Tracking Error: $err',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/passenger/tracking'),
                child: const Text('Back to Live Buses'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isFav, BusLiveState? busState) {
    final speedMultiplier = busState?.speedMultiplier ?? 1.0;
    final busNum = busState?.busNumber.isNotEmpty == true ? busState!.busNumber : '12A';
    final routeText = busState?.routeName.isNotEmpty == true ? busState!.routeName : 'Live Bus Tracking';

    return AppBar(
      backgroundColor: const Color(0xFF0F172A).withAlpha(220),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/passenger/home');
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bus $busNum',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: busState?.statusBadgeColor ?? const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  busState?.locationStatus ?? 'LIVE',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  routeText,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (busState != null) ...[
                const SizedBox(width: 6),
                Text(
                  '• ${busState.freshnessLabel}',
                  style: TextStyle(
                    color: busState.statusBadgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        // Dev Simulation Controls Toggle Button
        IconButton(
          tooltip: 'Simulation Controls',
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _showDevControls
                  ? const Color(0xFF6366F1)
                  : Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${speedMultiplier.toStringAsFixed(0)}x',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          onPressed: () {
            setState(() => _showDevControls = !_showDevControls);
          },
        ),
        // Favorite toggle
        IconButton(
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? const Color(0xFFEF4444) : Colors.white,
          ),
          onPressed: () =>
              ref.read(favoritesProvider.notifier).toggle(widget.busId),
        ),
        // Toggle panel
        IconButton(
          icon: Icon(
            _showDetailsPanel ? Icons.expand_less : Icons.expand_more,
            color: Colors.white,
          ),
          onPressed: () =>
              setState(() => _showDetailsPanel = !_showDetailsPanel),
        ),
      ],
    );
  }

  // ─── Top Live Status Header ─────────────────────────────────────────────────
  Widget _buildTopStatusBar(BusLiveState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: state.status.color.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: state.status.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: state.status.color.withAlpha(150),
                  blurRadius: 8,
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      state.status.label.toUpperCase(),
                      style: TextStyle(
                        color: state.status.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: state.statusBadgeColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: state.statusBadgeColor.withAlpha(150), width: 1),
                      ),
                      child: Text(
                        state.locationStatus,
                        style: TextStyle(
                          color: state.statusBadgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    if (state.status == BusJourneyStatus.stoppedAtStop &&
                        state.dwellTimeRemainingSeconds > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${state.dwellTimeRemainingSeconds}s wait)',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  state.statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${state.speed.toStringAsFixed(0)} km/h',
              style: TextStyle(
                color: state.speed > 0
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFF59E0B),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── "Is My Bus Coming?" Live Banner ───────────────────────────────────────
  Widget _buildIsMyBusComingBanner(BusLiveState state) {
    final boardingStop = state.selectedStopName ??
        (state.status == BusJourneyStatus.approachingStop
            ? state.nextStopName
            : state.currentStopName);
    final distanceKm =
        state.distanceToSelectedStop ?? state.distanceToNextStop;
    final etaMin = state.etaToSelectedStop ?? state.etaMinutes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF34D399), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🟢', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Your bus is coming',
                      style: TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        state.busNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Current: ${state.currentStopName} • Boarding: $boardingStop',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Distance: ${distanceKm.toStringAsFixed(1)} km • ETA: $etaMin min',
                  style: const TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Passenger Destination Stop ─────────────────────────────────────────────
  Widget _buildPassengerSelectedStopBanner(
      BusLiveState state, LiveBusTrackingRepository repo) {
    final stopName = state.selectedStopName ?? 'Selected Stop';
    final dist = state.distanceToSelectedStop ?? 0.0;
    final eta = state.etaToSelectedStop ?? 0;
    final stopsRem = state.stopsToSelectedStop ?? 0;

    String alertMessage = 'Heading towards $stopName';
    Color alertBg = const Color(0xFF6366F1);

    if (stopsRem == 0 && state.status == BusJourneyStatus.stoppedAtStop) {
      alertMessage = '🔔 Arrived at $stopName • Get Down Here!';
      alertBg = const Color(0xFFF59E0B);
    } else if (stopsRem == 0) {
      alertMessage = '🔔 Arriving at $stopName! Prepare to get down!';
      alertBg = const Color(0xFF3B82F6);
    } else if (stopsRem == 1) {
      alertMessage = '🔔 Your stop ($stopName) is NEXT!';
      alertBg = const Color(0xFF8B5CF6);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: alertBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: alertBg.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alertMessage,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
                Text(
                  '${dist.toStringAsFixed(1)} km away • ETA $eta min • $stopsRem stops left',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Colors.white70, size: 18),
            onPressed: () {
              repo.selectPassengerStop(widget.busId, null);
            },
          ),
        ],
      ),
    );
  }

  // ─── Floating Map Controls ──────────────────────────────────────────────────
  Widget _buildFloatingMapControls(LatLng busPos, double heading) {
    return Positioned(
      top: 170,
      right: 16,
      child: Column(
        children: [
          _buildMapBtn(
            icon: _followBus
                ? Icons.directions_bus_filled_rounded
                : Icons.directions_bus_outlined,
            color: _followBus ? const Color(0xFF6366F1) : const Color(0xFF475569),
            label: _followBus ? 'Following' : 'Follow',
            onTap: () {
              setState(() => _followBus = !_followBus);
              if (_followBus) _recenterBus(busPos, heading);
            },
          ),
          const SizedBox(height: 8),
          _buildMapBtn(
            icon: Icons.my_location_rounded,
            color: const Color(0xFF475569),
            label: 'Recenter',
            onTap: () {
              setState(() => _followBus = false);
              // Read location without watching — avoids rebuild subscription
              final userPos = ref.read(locationProvider).currentPosition;
              if (userPos != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(userPos.latitude, userPos.longitude),
                      zoom: 15.5,
                      tilt: 0,
                    ),
                  ),
                );
              } else if (!ref.read(locationProvider).isLocationEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location permission is required to show your position.')),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          _buildMapBtn(
            icon: Icons.route_rounded,
            color: const Color(0xFF475569),
            label: 'Fit Route',
            onTap: () {
              setState(() => _followBus = false);
              _fitRouteBounds();
            },
          ),
          const SizedBox(height: 8),
          _buildMapBtn(
            icon: Icons.add_rounded,
            color: const Color(0xFF475569),
            label: 'Zoom In',
            onTap: () {
              setState(() => _followBus = false);
              _mapController?.animateCamera(CameraUpdate.zoomIn());
            },
          ),
          const SizedBox(height: 8),
          _buildMapBtn(
            icon: Icons.remove_rounded,
            color: const Color(0xFF475569),
            label: 'Zoom Out',
            onTap: () {
              setState(() => _followBus = false);
              _mapController?.animateCamera(CameraUpdate.zoomOut());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ─── Developer Simulation Controls Overlay ──────────────────────────────────
  Widget _buildDevControlsPanel(
      BusLiveState state, LiveBusTrackingRepository repo) {
    return Positioned(
      top: 170,
      left: 16,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withAlpha(245),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 16,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DEV CONTROLS',
                  style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.w900),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showDevControls = false),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (state.isPaused) {
                        repo.resumeBus(widget.busId);
                      } else {
                        repo.pauseBus(widget.busId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isPaused
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    icon: Icon(
                        state.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 16),
                    label: Text(state.isPaused ? 'Resume' : 'Pause',
                        style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => repo.skipToNextStop(widget.busId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                icon: const Icon(Icons.skip_next_rounded, size: 16),
                label: const Text('Skip to Next Stop',
                    style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => repo.resetJourney(widget.busId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Reset to Ukkadam',
                    style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Speed Multiplier:',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1.0, 2.0, 5.0, 10.0].map((m) {
                final isCur = (state.speedMultiplier - m).abs() < 0.1;
                return GestureDetector(
                  onTap: () => repo.setSpeedMultiplier(widget.busId, m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCur
                          ? const Color(0xFF6366F1)
                          : Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${m.toStringAsFixed(0)}x',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isCur ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Journey Completed Overlay ──────────────────────────────────────────────
  Widget _buildJourneyCompletedOverlay(
      BusLiveState state, LiveBusTrackingRepository repo) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -6),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded,
                color: Color(0xFF22C55E), size: 48),
            const SizedBox(height: 12),
            const Text(
              '🏁 Journey Completed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bus ${state.busNumber} has arrived at destination (${state.currentStopName}).',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => repo.resetJourney(widget.busId),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('View Route Again',
                        style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/passenger/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back to Home',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sliding Bottom Details Panel ───────────────────────────────────────────
  Widget _buildBottomDetailsPanel(
      BusLiveState state, LiveBusTrackingRepository repo) {
    final allStops = MockLiveBusTrackingRepository.ukkadamPollachiStops;

    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.18,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -6),
              )
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_bus,
                            color: Colors.white, size: 16),
                        Text(
                          state.busNumber,
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
                        Text(
                          state.routeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.status == BusJourneyStatus.stoppedAtStop
                              ? '🟡 Stopped at ${state.currentStopName}'
                              : '🟢 Currently near ${state.currentStopName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: state.status == BusJourneyStatus.stoppedAtStop
                                ? const Color(0xFFD97706)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${state.etaMinutes} min',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const Text(
                        'Est. Arrival',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT STOP',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.currentStopName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.status == BusJourneyStatus.stoppedAtStop
                                ? 'At Platform'
                                : 'Departed',
                            style: TextStyle(
                              fontSize: 11,
                              color: state.status ==
                                      BusJourneyStatus.stoppedAtStop
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEXT STOP',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                                letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.nextStopName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF14532D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.distanceToNextStop.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Journey Progress',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A)),
                  ),
                  Text(
                    '${state.progressPercentage.toStringAsFixed(0)}% completed',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (state.progressPercentage / 100.0).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Route Stops (Tap to select your stop)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),

              Column(
                children: List.generate(allStops.length, (i) {
                  final stop = allStops[i];
                  final isPassed = i < state.currentStopIndex;
                  final isCurrent = i == state.currentStopIndex;
                  final isNext = i == state.nextStopIndex;
                  final isSelected = stop.id == state.selectedStopId;

                  return GestureDetector(
                    onTap: () {
                      repo.selectPassengerStop(widget.busId, stop.id);
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF43F5E)
                                      : (isCurrent
                                          ? const Color(0xFF6366F1)
                                          : (isPassed
                                              ? const Color(0xFF10B981)
                                              : Colors.white)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFF43F5E)
                                        : (isCurrent
                                            ? const Color(0xFF6366F1)
                                            : (isPassed
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFCBD5E1))),
                                    width: 2.5,
                                  ),
                                ),
                                child: Center(
                                  child: isSelected
                                      ? const Icon(Icons.star,
                                          color: Colors.white, size: 12)
                                      : (isPassed
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 12)
                                          : (isCurrent
                                              ? const Icon(
                                                  Icons.directions_bus,
                                                  color: Colors.white,
                                                  size: 11)
                                              : null)),
                                ),
                              ),
                              if (i < allStops.length - 1)
                                Container(
                                  width: 2.5,
                                  height: 38,
                                  color: isPassed
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFE2E8F0),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stop.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isCurrent || isSelected
                                              ? FontWeight.w900
                                              : (isPassed
                                                  ? FontWeight.w600
                                                  : FontWeight.w500),
                                          color: isSelected
                                              ? const Color(0xFFF43F5E)
                                              : (isCurrent
                                                  ? const Color(0xFF6366F1)
                                                  : (isPassed
                                                      ? const Color(0xFF0F172A)
                                                      : const Color(0xFF64748B))),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Text(
                                          'Your Selected Stop ⭐',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFFF43F5E),
                                              fontWeight: FontWeight.bold),
                                        )
                                      else if (isCurrent &&
                                          state.status ==
                                              BusJourneyStatus.stoppedAtStop)
                                        Text(
                                          'Bus Stopped Here (${state.dwellTimeRemainingSeconds}s wait)',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFFD97706),
                                              fontWeight: FontWeight.bold),
                                        )
                                      else if (isNext)
                                        const Text(
                                          'Next Stop',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPassed
                                          ? const Color(0xFF10B981)
                                              .withAlpha(15)
                                          : (isCurrent
                                              ? const Color(0xFF6366F1)
                                                  .withAlpha(20)
                                              : const Color(0xFFF1F5F9)),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isPassed
                                          ? 'Passed'
                                          : (isCurrent
                                              ? 'Bus here'
                                              : 'Upcoming'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isPassed
                                            ? const Color(0xFF10B981)
                                            : (isCurrent
                                                ? const Color(0xFF6366F1)
                                                : const Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricChip(
                    icon: Icons.speed_rounded,
                    label: 'Speed',
                    value: '${state.speed.toStringAsFixed(0)} km/h',
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildMetricChip(
                    icon: Icons.alt_route_rounded,
                    label: 'Travelled',
                    value: '${state.distanceTravelled.toStringAsFixed(1)} km',
                    color: const Color(0xFF10B981),
                  ),
                  _buildMetricChip(
                    icon: Icons.pin_drop_outlined,
                    label: 'Remaining',
                    value: '${state.distanceRemaining.toStringAsFixed(1)} km',
                    color: const Color(0xFF6366F1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Isolated Google Map Widget ───────────────────────────────────────────────
//
// This widget owns its own state for markers and polylines.
// It only rebuilds the GoogleMap when markers actually change.
// The parent passes BusLiveState; this widget diffs it internally.

class _LiveMapWidget extends StatefulWidget {
  final String busId;
  final BusLiveState busState;
  final LatLng initialPos;
  final void Function(GoogleMapController) onMapReady;
  final VoidCallback onUserPan;
  final LiveBusTrackingRepository repo;

  const _LiveMapWidget({
    super.key,
    required this.busId,
    required this.busState,
    required this.initialPos,
    required this.onMapReady,
    required this.onUserPan,
    required this.repo,
  });

  @override
  _LiveMapWidgetState createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<_LiveMapWidget> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Track last values to avoid unnecessary rebuilds
  LatLng _lastBusPos = const LatLng(0, 0);
  double _lastHeading = 0;
  int _lastRoutePointIndex = -1;
  String? _lastSelectedStopId;
  BusJourneyStatus? _lastStatus;

  // Precomputed stop marker positions (constant — never changes)
  static final List<LatLng> _stopPositions = MockLiveBusTrackingRepository
      .ukkadamPollachiStops
      .map((s) => LatLng(s.lat, s.lng))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _buildInitialPolylines();
    _rebuildMarkers(widget.busState, widget.initialPos);
  }

  @override
  void didUpdateWidget(_LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final state = widget.busState;
    final newPos = LatLng(state.latitude, state.longitude);

    // Determine what changed
    final posChanged = (newPos.latitude - _lastBusPos.latitude).abs() > 0.000001 ||
        (newPos.longitude - _lastBusPos.longitude).abs() > 0.000001;
    final headingChanged = (state.heading - _lastHeading).abs() > 1.0;
    final routePointChanged = state.currentRoutePointIndex != _lastRoutePointIndex;
    final selectedStopChanged = state.selectedStopId != _lastSelectedStopId;
    final statusChanged = state.status != _lastStatus;

    // Only rebuild markers when something map-relevant changed
    if (posChanged || headingChanged || selectedStopChanged || statusChanged) {
      _rebuildMarkers(state, widget.initialPos);
    }

    // Only rebuild polylines when the route progress segment changes
    if (routePointChanged) {
      _rebuildPolylines(state, widget.initialPos);
    }
  }

  // Called from parent's animation listener — no setState on parent
  void updateAnimatedPosition(LatLng animatedPos) {
    if (!mounted) return;
    // Only update if the animated position meaningfully differs
    final latDiff = (animatedPos.latitude - _lastBusPos.latitude).abs();
    final lngDiff = (animatedPos.longitude - _lastBusPos.longitude).abs();
    if (latDiff < 0.000001 && lngDiff < 0.000001) return;

    setState(() {
      _updateBusMarkerPosition(animatedPos);
    });
  }

  void _updateBusMarkerPosition(LatLng pos) {
    // Surgically replace only the bus marker, preserving all stop markers
    final busMarkerId = MarkerId('bus_${widget.busId}');
    final updatedMarkers = _markers.map((m) {
      if (m.markerId == busMarkerId) {
        return m.copyWith(positionParam: pos);
      }
      return m;
    }).toSet();
    _markers = updatedMarkers;
    _lastBusPos = pos;
  }

  void _buildInitialPolylines() {
    // Build polylines once; they get updated when route progress changes
    _polylines = {
      Polyline(
        polylineId: const PolylineId('completed_route'),
        points: const [LatLng(10.9902, 76.9607)], // placeholder
        color: const Color(0xFF10B981),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
      Polyline(
        polylineId: const PolylineId('remaining_route'),
        points: _staticPolylinePoints,
        color: const Color(0xFF6366F1),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  void _rebuildPolylines(BusLiveState state, LatLng currentPos) {
    final allPoly = _staticPolylinePoints;
    final splitIdx =
        state.currentRoutePointIndex.clamp(0, allPoly.length - 1);

    final completedPoints = <LatLng>[];
    for (int i = 0; i <= splitIdx; i++) {
      completedPoints.add(allPoly[i]);
    }
    completedPoints.add(currentPos);

    final remainingPoints = <LatLng>[currentPos];
    for (int i = splitIdx + 1; i < allPoly.length; i++) {
      remainingPoints.add(allPoly[i]);
    }

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('completed_route'),
          points: completedPoints,
          color: const Color(0xFF10B981),
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
        Polyline(
          polylineId: const PolylineId('remaining_route'),
          points: remainingPoints,
          color: const Color(0xFF6366F1),
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
      _lastRoutePointIndex = state.currentRoutePointIndex;
    });
  }

  void _rebuildMarkers(BusLiveState state, LatLng currentPos) {
    final allStops = MockLiveBusTrackingRepository.ukkadamPollachiStops;
    final newMarkers = <Marker>{};

    // Bus marker
    newMarkers.add(
      Marker(
        markerId: MarkerId('bus_${widget.busId}'),
        position: currentPos,
        rotation: state.heading,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: '🚌 Bus ${state.busNumber} (${state.status.label})',
          snippet: state.status == BusJourneyStatus.stoppedAtStop
              ? 'Stopped at ${state.currentStopName} • 0 km/h'
              : 'Speed: ${state.speed.toStringAsFixed(0)} km/h • Next: ${state.nextStopName}',
        ),
        zIndexInt: 10,
      ),
    );

    // Stop markers — use precomputed positions
    for (int i = 0; i < allStops.length; i++) {
      final stop = allStops[i];
      final isSelected = stop.id == state.selectedStopId;
      final isCurrent = i == state.currentStopIndex;
      final isNext = i == state.nextStopIndex;
      final isPassed = i < state.currentStopIndex;

      double hue;
      String snippet;

      if (isSelected) {
        hue = BitmapDescriptor.hueRose;
        snippet = '⭐ YOUR DESTINATION (ETA: ${state.etaToSelectedStop ?? state.etaMinutes} min)';
      } else if (isCurrent && state.status == BusJourneyStatus.stoppedAtStop) {
        hue = BitmapDescriptor.hueYellow;
        snippet = '🟡 Bus is currently stopped here (Departing in ${state.dwellTimeRemainingSeconds}s)';
      } else if (isNext) {
        hue = BitmapDescriptor.hueBlue;
        snippet = '🔵 Next stop (${state.distanceToNextStop.toStringAsFixed(1)} km away)';
      } else if (isPassed) {
        hue = BitmapDescriptor.hueGreen;
        snippet = '✓ Passed';
      } else {
        hue = BitmapDescriptor.hueOrange;
        snippet = 'Upcoming stop';
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: _stopPositions[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${stop.name}',
            snippet: snippet,
            onTap: () {
              widget.repo.selectPassengerStop(widget.busId, stop.id);
            },
          ),
          onTap: () {
            widget.repo.selectPassengerStop(widget.busId, stop.id);
          },
          zIndexInt: isSelected ? 9 : (isCurrent ? 8 : 5),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
      _lastBusPos = currentPos;
      _lastHeading = state.heading;
      _lastSelectedStopId = state.selectedStopId;
      _lastStatus = state.status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.busState;
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialPos,
        zoom: 14.5,
        bearing: state.heading,
        tilt: 30.0,
      ),
      onMapCreated: (ctrl) {
        widget.onMapReady(ctrl);
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onCameraMoveStarted: widget.onUserPan,
    );
  }
}
