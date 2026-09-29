import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class PassengerRoutesScreen extends ConsumerStatefulWidget {
  const PassengerRoutesScreen({super.key});

  @override
  ConsumerState<PassengerRoutesScreen> createState() =>
      _PassengerRoutesScreenState();
}

class _PassengerRoutesScreenState
    extends ConsumerState<PassengerRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const _mockRoutes = [
    {
      'id': 'r12a',
      'number': '12A',
      'name': 'Gandhipuram – Ukkadam',
      'stops': 5,
      'buses': 3,
      'status': 'Active',
    },
    {
      'id': 'r24',
      'number': '24',
      'name': 'Gandhipuram – Singanallur',
      'stops': 5,
      'buses': 2,
      'status': 'Active',
    },
    {
      'id': 'r5b',
      'number': '5B',
      'name': 'RS Puram – Kovaipudur',
      'stops': 5,
      'buses': 1,
      'status': 'Delayed',
    },
    {
      'id': 'r88',
      'number': '88',
      'name': 'Vadavalli – Tiruppur',
      'stops': 5,
      'buses': 2,
      'status': 'Active',
    },
    {
      'id': 'r20c',
      'number': '20C',
      'name': 'Mettupalayam – Coimbatore',
      'stops': 5,
      'buses': 0,
      'status': 'Not Running',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _mockRoutes;
    final q = _query.toLowerCase();
    return _mockRoutes.where((r) {
      return r['number'].toString().toLowerCase().contains(q) ||
          r['name'].toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            // Header
            SliverAppBar(
              backgroundColor: const Color(0xFF0F172A),
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: 110,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Routes',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        '${_mockRoutes.length} routes available',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Search
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search,
                              color: Color(0xFF94A3B8)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _query = v),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    'Search bus or destination...',
                                hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Route cards
            if (_filtered.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🚌', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text('No routes found',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildRouteCard(_filtered[i]),
                    childCount: _filtered.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final status = route['status'] as String;
    final buses = route['buses'] as int;

    Color statusColor;
    switch (status) {
      case 'Active':
        statusColor = const Color(0xFF22C55E);
        break;
      case 'Delayed':
        statusColor = const Color(0xFFF59E0B);
        break;
      default:
        statusColor = const Color(0xFFEF4444);
    }

    return GestureDetector(
      onTap: () => context.go('/passenger/route/${route['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: status == 'Not Running'
                          ? const LinearGradient(colors: [
                              Color(0xFF94A3B8),
                              Color(0xFF64748B)
                            ])
                          : const LinearGradient(
                              colors: [
                                Color(0xFF0F172A),
                                Color(0xFF1E3A5F)
                              ],
                            ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(route['number'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(route['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.stop_circle_outlined,
                                size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('${route['stops']} stops',
                                style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.directions_bus,
                                size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('$buses ${buses == 1 ? 'bus' : 'buses'} active',
                                style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('View all stops & live buses',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 12)),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF94A3B8), size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
