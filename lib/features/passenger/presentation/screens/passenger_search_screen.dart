import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/location_provider.dart';
import '../../data/services/mock_live_bus_service.dart';
import '../../data/repositories/mock_bus_stop_repository.dart';
import '../../domain/models/bus_stop_info.dart';

class PassengerSearchScreen extends ConsumerStatefulWidget {
  const PassengerSearchScreen({super.key});

  @override
  ConsumerState<PassengerSearchScreen> createState() => _PassengerSearchScreenState();
}

class _PassengerSearchScreenState extends ConsumerState<PassengerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final service = ref.read(mockLiveBusServiceProvider);
    final allBuses = service.allBuses;
    final locationState = ref.watch(locationProvider);

    // Popular destinations
    const popularDestinations = [
      'Coimbatore',
      'Pollachi',
      'Ukkadam',
      'Gandhipuram',
      'Kinathukadavu',
      'Ettimadai',
      'Singanallur',
      'Town Hall',
    ];

    // Parse source -> destination if query contains "to" or "->"
    String? sourceQuery;
    String? destQuery;
    final lowerQuery = _query.toLowerCase().trim();
    if (lowerQuery.contains(' to ')) {
      final parts = lowerQuery.split(' to ');
      if (parts.length == 2) {
        sourceQuery = parts[0].trim();
        destQuery = parts[1].trim();
      }
    } else if (lowerQuery.contains('→')) {
      final parts = lowerQuery.split('→');
      if (parts.length == 2) {
        sourceQuery = parts[0].trim();
        destQuery = parts[1].trim();
      }
    }

    // Filter buses
    List<LiveBusInfo> matchingBuses = [];
    if (sourceQuery != null && destQuery != null) {
      matchingBuses = allBuses.where((b) =>
        (b.origin.toLowerCase().contains(sourceQuery!) || b.allStops.any((s) => s.name.toLowerCase().contains(sourceQuery!))) &&
        (b.destination.toLowerCase().contains(destQuery!) || b.allStops.any((s) => s.name.toLowerCase().contains(destQuery!)))
      ).toList();
    } else if (lowerQuery.isNotEmpty) {
      matchingBuses = allBuses.where((b) =>
        b.busNumber.toLowerCase().contains(lowerQuery) ||
        b.origin.toLowerCase().contains(lowerQuery) ||
        b.destination.toLowerCase().contains(lowerQuery) ||
        b.allStops.any((s) => s.name.toLowerCase().contains(lowerQuery))
      ).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (v) {
                              setState(() => _query = v);
                              if (v.trim().isNotEmpty) {
                                ref.read(recentSearchesProvider.notifier).add(v);
                              }
                            },
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Bus, stop or "Pollachi to Coimbatore"...',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_query.isEmpty) ...[
                    // Recent Searches
                    if (recentSearches.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Searches',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          GestureDetector(
                            onTap: () => ref.read(recentSearchesProvider.notifier).clear(),
                            child: const Text('Clear All',
                                style: TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentSearches.map((s) => ActionChip(
                              backgroundColor: Colors.white,
                              labelStyle: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                              avatar: const Icon(Icons.history_rounded, size: 14, color: Color(0xFF64748B)),
                              label: Text(s),
                              onPressed: () {
                                _searchController.text = s;
                                setState(() => _query = s);
                              },
                            )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Popular Destinations
                    const Text('Popular Destinations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: popularDestinations.map((dest) => GestureDetector(
                            onTap: () {
                              _searchController.text = dest;
                              setState(() => _query = dest);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFDDD6FE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF7C3AED)),
                                  const SizedBox(width: 6),
                                  Text(dest,
                                      style: const TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ),
                          )).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Nearby Stops Section
                    const Text('Nearby Stops',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    FutureBuilder<List<BusStopInfo>>(
                      future: MockBusStopRepository().getNearbyStops(locationState.currentPosition),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final stops = snapshot.data!;
                        return Column(
                          children: stops.map((stop) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.bus_alert_rounded, color: Color(0xFF0F172A), size: 20),
                                  ),
                                  title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  subtitle: Text(stop.address, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                                  onTap: () => context.push('/passenger/stop/${Uri.encodeComponent(stop.name)}'),
                                ),
                              )).toList(),
                        );
                      },
                    ),
                  ] else ...[
                    // Search Results
                    Text(
                      sourceQuery != null && destQuery != null
                          ? 'Routes: $sourceQuery → $destQuery'
                          : 'Search Results for "$_query"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 14),
                    if (matchingBuses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Text('🔍', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 12),
                              Text('No matching buses found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              SizedBox(height: 6),
                              Text('Try searching bus number, stop or "Pollachi to Coimbatore"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: matchingBuses.map((bus) => Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          bus.busNumber,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${bus.origin} → ${bus.destination}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('🟢 LIVE',
                                            style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Stops: ${bus.allStops.map((s) => s.name).join(' • ')}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      onPressed: () => context.push('/passenger/live-tracking/${bus.busId}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.navigation_rounded, size: 16),
                                      label: const Text('Track Live / View Route',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
