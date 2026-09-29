import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() =>
      _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final _fromController = TextEditingController(text: 'Current Location');
  final _toController = TextEditingController();
  bool _showResults = false;

  static final _tripOptions = [
    {
      'busId': 'bus_12a',
      'number': '12A',
      'type': 'Direct',
      'transfers': 0,
      'duration': '25 min',
      'walking': '3 min walk',
      'arrival': '7:45 PM',
      'status': 'On Time',
      'route': 'Gandhipuram → Town Hall → Ukkadam',
      'statusColor': const Color(0xFF22C55E),
    },
    {
      'busId': 'bus_24',
      'number': '24',
      'type': '1 transfer',
      'transfers': 1,
      'duration': '32 min',
      'walking': '5 min walk',
      'arrival': '7:52 PM',
      'status': 'Delayed',
      'route': 'Gandhipuram → Singanallur → Ukkadam',
      'statusColor': const Color(0xFFF59E0B),
    },
    {
      'busId': 'bus_5b',
      'number': '5B',
      'type': 'Slower',
      'transfers': 0,
      'duration': '40 min',
      'walking': '2 min walk',
      'arrival': '8:00 PM',
      'status': 'On Time',
      'route': 'RS Puram → Peelamedu → Ukkadam',
      'statusColor': const Color(0xFF22C55E),
    },
  ];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0F172A),
              pinned: true,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => context.go('/passenger/home'),
              ),
              expandedHeight: 80,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              flexibleSpace: const FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.fromLTRB(64, 0, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plan Your Trip',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
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
                    // From / To card
                    Container(
                      padding: const EdgeInsets.all(20),
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
                        children: [
                          // From
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E)
                                      .withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.my_location_rounded,
                                    color: Color(0xFF22C55E), size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: _fromController,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                      fontSize: 15),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    labelText: 'From',
                                    labelStyle: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Divider(
                                color: Color(0xFFE2E8F0), thickness: 1),
                          ),
                          // To
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on_rounded,
                                    color: Color(0xFFEF4444), size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: _toController,
                                  onChanged: (v) =>
                                      setState(() {}),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                      fontSize: 15),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Where to?',
                                    hintStyle: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 15),
                                    labelText: 'To',
                                    labelStyle: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick destination chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['Ukkadam', 'Singanallur', 'Peelamedu', 'RS Puram']
                          .map((d) => GestureDetector(
                                onTap: () {
                                  _toController.text = d;
                                  setState(() {
                                    _showResults = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                  ),
                                  child: Text(d,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Color(0xFF475569))),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_toController.text.isNotEmpty) {
                            setState(() => _showResults = true);
                          }
                        },
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Find Routes',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    if (_showResults) ...[
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Text('Possible Routes',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                          const Spacer(),
                          Text(
                            '${_tripOptions.length} options',
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._tripOptions.asMap().entries.map(
                            (entry) => _buildTripOption(
                                entry.value, entry.key == 0, context),
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripOption(
      Map<String, dynamic> option, bool isBest, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isBest
            ? Border.all(color: const Color(0xFF6366F1), width: 2)
            : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          if (isBest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Center(
                child: Text('⭐ Best Option',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(option['number'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(option['type'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A))),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (option['statusColor'] as Color)
                                      .withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(option['status'] as String,
                                    style: TextStyle(
                                        color: option['statusColor'] as Color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(option['route'] as String,
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTripStat(
                        Icons.access_time_rounded,
                        option['duration'] as String,
                        'Duration'),
                    _buildTripStat(Icons.directions_walk_rounded,
                        option['walking'] as String, 'Walking'),
                    _buildTripStat(Icons.schedule_rounded,
                        option['arrival'] as String, 'Arrives'),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => context.go(
                      '/passenger/live-tracking/${option['busId']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBest
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Take This Route',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F172A))),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
