import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/discovery_providers.dart';
import '../../domain/models/journey_model.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final _fromController = TextEditingController(text: 'Current Location');
  final _toController = TextEditingController(text: 'Pollachi');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeTripSearch();
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _executeTripSearch() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (to.isEmpty) return;

    ref.read(journeySearchProvider.notifier).search(
          from: from.isEmpty ? 'Current Location' : from,
          to: to,
        );
  }

  void _swapFromTo() {
    final from = _fromController.text;
    final to = _toController.text;
    setState(() {
      _fromController.text = to.isEmpty ? 'Current Location' : to;
      _toController.text = from == 'Current Location' ? 'Pollachi' : from;
    });
    _executeTripSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(journeySearchProvider);
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Trip Planner',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Input Card (From → To) ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // FROM Field
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.my_location_rounded,
                                  color: Color(0xFF16A34A), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _fromController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: 'FROM',
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_fromController.text != 'Current Location')
                              IconButton(
                                icon: const Icon(Icons.gps_fixed_rounded,
                                    color: Color(0xFF6366F1), size: 18),
                                tooltip: 'Use Current Location',
                                onPressed: () {
                                  setState(() {
                                    _fromController.text = 'Current Location';
                                  });
                                  _executeTripSearch();
                                },
                              ),
                          ],
                        ),

                        // Swap Divider
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Container(
                              width: 2,
                              height: 20,
                              color: const Color(0xFFE2E8F0),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _swapFromTo,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Icon(Icons.swap_vert_rounded,
                                    color: Color(0xFF0F172A), size: 18),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),

                        // TO Field
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: Color(0xFFDC2626), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _toController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: 'TO',
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  hintText: 'Enter destination...',
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _executeTripSearch(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _executeTripSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.directions_bus_rounded, size: 18),
                      label: const Text(
                        'Search Buses',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Quick Destination Chips ──────────────────────────────────────
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  'Pollachi',
                  'Coimbatore',
                  'Ukkadam',
                  'Gandhipuram',
                  'Kinathukadavu',
                  'Singanallur',
                ].map((dest) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(dest),
                      labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      onPressed: () {
                        setState(() => _toController.text = dest);
                        _executeTripSearch();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Results Body ─────────────────────────────────────────────────
            Expanded(
              child: searchState.isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF0F172A)),
                          SizedBox(height: 16),
                          Text('Finding best travel routes...',
                              style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : searchState.result != null
                      ? _buildTripResults(searchState.result!, locationState)
                      : const Center(
                          child: Text('Enter a destination to view travel options.'),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Trip Results View (Requirements 14, 15, 16) ───────────────────────────
  Widget _buildTripResults(
      JourneySearchResult result, LocationState locationState) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Boarding Stop Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.directions_walk_rounded,
                  color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Board at: ${result.recommendedBoardingStop.name} (${result.recommendedBoardingStop.distanceMeters.round()} m • ${result.recommendedBoardingStop.walkMinutes} min walk)',
                  style: const TextStyle(
                      color: Color(0xFF312E81),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Route Options Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trip Options',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            Text(
              '${result.allOptions.length} available',
              style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Route Options Cards (Option 1, Option 2, etc.)
        ...result.allOptions.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final option = entry.value;
          return _buildTripOptionCard(idx, option);
        }),
      ],
    );
  }

  Widget _buildTripOptionCard(int optionNumber, JourneyBusOption opt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: opt.isDirect
              ? const Color(0xFF6366F1).withAlpha(50)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: opt.isDirect
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFFFFBEB),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OPTION $optionNumber',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: opt.isLive
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    opt.isLive ? '🟢 LIVE NOW' : '🕒 UPCOMING',
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
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Bus number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🚌 ${opt.busNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.routeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt.isDirect ? 'Direct bus' : '${opt.transfers} transfer required',
                            style: TextStyle(
                              color: opt.isDirect
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Stats Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTripStat('Walk', '${opt.walkingMinutes} min'),
                      Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                      _buildTripStat('ETA to Board', '${opt.etaMinutes} min'),
                      Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                      _buildTripStat('Total Journey', opt.journeyDuration),
                    ],
                  ),
                ),

                if (opt.currentLocation != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Current live location: ${opt.currentLocation}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500),
                  ),
                ],

                const SizedBox(height: 16),

                // Track Live Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/passenger/live-tracking/${opt.busId}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: Text(
                      opt.isLive ? 'Track Live' : 'View Bus Tracking',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ],
    );
  }
}
