import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/location_provider.dart';
import '../../data/services/mock_live_bus_service.dart';
import '../../data/services/passenger_discovery_service.dart';
import '../../domain/models/bus_stop_info.dart';
import '../../domain/models/journey_model.dart';
import '../../data/repositories/mock_bus_stop_repository.dart';

class PassengerSearchScreen extends ConsumerStatefulWidget {
  const PassengerSearchScreen({super.key});

  @override
  ConsumerState<PassengerSearchScreen> createState() =>
      _PassengerSearchScreenState();
}

class _PassengerSearchScreenState extends ConsumerState<PassengerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearching = false;
  JourneySearchResult? _destinationJourneyResult;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) async {
    setState(() {
      _query = query;
    });

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _destinationJourneyResult = null;
        _isSearching = false;
      });
      return;
    }

    // Save to recent searches
    ref.read(recentSearchesProvider.notifier).add(trimmed);

    // If query looks like a destination (not purely a number or "stop")
    final isBusNumber = RegExp(r'^\d+[a-zA-Z]?$').hasMatch(trimmed);
    final isStopQuery = trimmed.toLowerCase().contains('stop') ||
        trimmed.toLowerCase().contains('stand');

    if (!isBusNumber && !isStopQuery) {
      setState(() => _isSearching = true);
      final locationState = ref.read(locationProvider);
      final service = ref.read(passengerDiscoveryServiceProvider);
      try {
        final res = await service.planJourney(
          from: 'Current Location',
          to: trimmed,
          userPos: locationState.currentPosition,
        );
        if (mounted) {
          setState(() {
            _destinationJourneyResult = res;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    } else {
      setState(() {
        _destinationJourneyResult = null;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final service = ref.read(mockLiveBusServiceProvider);
    final allBuses = service.allBuses;
    final locationState = ref.watch(locationProvider);

    final lowerQuery = _query.toLowerCase().trim();
    final isBusNumberSearch = RegExp(r'^\d+[a-zA-Z]?$').hasMatch(lowerQuery);

    // Filter buses by bus number or route stops
    final matchingBuses = allBuses.where((b) {
      if (isBusNumberSearch) {
        return b.busNumber.toLowerCase() == lowerQuery ||
            b.busNumber.toLowerCase().contains(lowerQuery);
      }
      return b.busNumber.toLowerCase().contains(lowerQuery) ||
          b.origin.toLowerCase().contains(lowerQuery) ||
          b.destination.toLowerCase().contains(lowerQuery) ||
          b.allStops.any((s) => s.name.toLowerCase().contains(lowerQuery));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _onQueryChanged,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search destination, bus number, or stop...',
                          hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 13),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Color(0xFF6366F1), size: 20),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Color(0xFF94A3B8), size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onQueryChanged('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: _query.isEmpty
                  ? _buildDefaultSearchScreen(recentSearches, locationState)
                  : _buildSearchResults(
                      lowerQuery,
                      isBusNumberSearch,
                      matchingBuses,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Default Search Screen (Before Typing) ─────────────────────────────────
  Widget _buildDefaultSearchScreen(
      List<String> recentSearches, LocationState locationState) {
    // Location-relevant suggested destinations
    final suggestedDestinations = [
      'Pollachi',
      'Coimbatore',
      'Ukkadam',
      'Gandhipuram',
      'Kinathukadavu',
      'Singanallur',
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Recent Searches
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(recentSearchesProvider.notifier).clear(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches
                .map(
                  (s) => ActionChip(
                    backgroundColor: Colors.white,
                    labelStyle: const TextStyle(
                        color: Color(0xFF334155), fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    avatar: const Icon(Icons.history_rounded,
                        size: 14, color: Color(0xFF64748B)),
                    label: Text(s),
                    onPressed: () {
                      _searchController.text = s;
                      _onQueryChanged(s);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // 2. Location-Relevant Suggested Destinations
        const Text(
          'Suggested Destinations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestedDestinations
              .map(
                (dest) => GestureDetector(
                  onTap: () {
                    _searchController.text = dest;
                    _onQueryChanged(dest);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded,
                            size: 14, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 6),
                        Text(
                          dest,
                          style: const TextStyle(
                            color: Color(0xFF4338CA),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 28),

        // 3. Nearby Stops
        const Text(
          'Nearby Bus Stops',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<BusStopInfo>>(
          future: MockBusStopRepository()
              .getNearbyStops(locationState.currentPosition),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final stops = snapshot.data!;
            return Column(
              children: stops
                  .map(
                    (stop) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pin_drop_rounded,
                              color: Color(0xFF0F172A), size: 18),
                        ),
                        title: Text(stop.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(stop.address,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: Color(0xFF94A3B8)),
                        onTap: () {
                          _searchController.text = stop.name;
                          _onQueryChanged(stop.name);
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // ─── Search Results ────────────────────────────────────────────────────────
  Widget _buildSearchResults(
    String query,
    bool isBusNumberSearch,
    List<LiveBusInfo> matchingBuses,
  ) {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0F172A)),
            SizedBox(height: 16),
            Text('Planning journey...',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // ── 1. Bus Number Search Result (e.g. "12A") ─────────────────────────────
    if (isBusNumberSearch) {
      return _buildBusNumberResults(query, matchingBuses);
    }

    // ── 2. Destination Search Result (e.g. "Pollachi") ───────────────────────
    if (_destinationJourneyResult != null) {
      return _buildDestinationJourneyResults(_destinationJourneyResult!);
    }

    // ── 3. Bus Stop Search Result (e.g. "Gandhipuram Bus Stop") ──────────────
    return _buildGeneralSearchResults(query, matchingBuses);
  }

  // ─── Destination Journey Results (Requirements 7, 8, 9, 10, 23) ────────────
  Widget _buildDestinationJourneyResults(JourneySearchResult result) {
    final locationState = ref.watch(locationProvider);
    final currentLocName = locationState.address ?? 'Current Location';

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // From → To Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: Color(0xFF22C55E), size: 16),
                  const SizedBox(width: 8),
                  const Text('FROM:',
                      style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentLocName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  const Text('TO:',
                      style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.toQuery.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Nearby Boarding Stop Card (Requirement 19)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_walk_rounded,
                    color: Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nearby Boarding Stop',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(result.recommendedBoardingStop.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(
                      '${result.recommendedBoardingStop.distanceMeters.round()} m away • ${result.recommendedBoardingStop.walkMinutes} min walk',
                      style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Alternative Boarding Stop (if better)
        if (result.alternativeBoardingStops.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF64748B), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alternative stop: ${result.alternativeBoardingStops.first.name} (${result.alternativeBoardingStops.first.distanceMeters.round()} m away)',
                    style:
                        const TextStyle(color: Color(0xFF475569), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Available Buses Section
        const Text('Available Buses',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 12),

        // Direct bus cards
        if (result.directRoutes.isNotEmpty)
          ...result.directRoutes
              .map((opt) => _buildJourneyBusOptionCard(opt)),

        // Connecting bus cards (Requirement 10)
        if (result.connectingRoutes.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Connecting Options (Transfers)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          ...result.connectingRoutes
              .map((opt) => _buildJourneyBusOptionCard(opt)),
        ],
      ],
    );
  }

  // ─── Journey Bus Option Card ───────────────────────────────────────────────
  Widget _buildJourneyBusOptionCard(JourneyBusOption opt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
        border: Border.all(
          color: opt.isDirect
              ? const Color(0xFF6366F1).withAlpha(50)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Bus Number badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🚌 ${opt.busNumber}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${opt.origin} → ${opt.destination}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A)),
                ),
              ),
              // Live / Upcoming Badge (Requirement 16)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: opt.isLive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  opt.isLive ? '🟢 LIVE' : '🕒 UPCOMING',
                  style: TextStyle(
                    color: opt.isLive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Journey Stats Row
          Row(
            children: [
              if (opt.isDirect)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Direct',
                      style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${opt.transfers} Transfer',
                      style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              const SizedBox(width: 10),
              Text('ETA to boarding: ${opt.etaMinutes} min',
                  style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const Spacer(),
              Text('Journey: ${opt.journeyDuration}',
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),

          if (opt.currentLocation != null) ...[
            const SizedBox(height: 8),
            Text(
              'Current: ${opt.currentLocation}  •  Next: ${opt.nextStop ?? "Approaching"}',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
            ),
          ],

          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.push('/passenger/live-tracking/${opt.busId}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: opt.isLive
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF475569),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: Icon(
                  opt.isLive
                      ? Icons.navigation_rounded
                      : Icons.visibility_rounded,
                  size: 16),
              label: Text(
                opt.isLive ? 'Track Live' : 'View Schedule',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search by Bus Number (Requirement 21) ─────────────────────────────────
  Widget _buildBusNumberResults(
      String query, List<LiveBusInfo> matchingBuses) {
    if (matchingBuses.isEmpty) {
      return const Center(child: Text('No bus found with this number.'));
    }

    final bus = matchingBuses.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Bus ${bus.busNumber}',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        Text('Route: ${bus.origin} → ${bus.destination}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        const SizedBox(height: 16),

        const Text('Active Live Buses on this Route:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),

        // Bus instance #1
        _buildBusInstanceCard(
          busNumber: bus.busNumber,
          label: 'Bus ${bus.busNumber} #1',
          currentStop: 'Madukkarai',
          etaMinutes: 7,
          busId: bus.busId,
        ),
        // Bus instance #2
        _buildBusInstanceCard(
          busNumber: bus.busNumber,
          label: 'Bus ${bus.busNumber} #2',
          currentStop: 'Kinathukadavu',
          etaMinutes: 18,
          busId: bus.busId,
        ),
      ],
    );
  }

  Widget _buildBusInstanceCard({
    required String busNumber,
    required String label,
    required String currentStop,
    required int etaMinutes,
    required String busId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              busNumber,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Current: $currentStop  •  ETA: $etaMinutes min',
                    style: const TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/passenger/live-tracking/$busId'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Track Bus',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── General Search Results ────────────────────────────────────────────────
  Widget _buildGeneralSearchResults(
      String query, List<LiveBusInfo> matchingBuses) {
    if (matchingBuses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text('No results found for "$query"',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              const Text('Try searching "Pollachi", "12A", or a bus stop.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Results for "$query"',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        ...matchingBuses.map((bus) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          bus.busNumber,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${bus.origin} → ${bus.destination}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const Text('🟢 LIVE',
                          style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Stops: ${bus.allStops.map((s) => s.name).join(" • ")}',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/passenger/live-tracking/${bus.busId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: const Text('Track Bus Live',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
