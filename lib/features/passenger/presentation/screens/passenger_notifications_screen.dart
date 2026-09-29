import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PassengerNotificationsScreen extends ConsumerWidget {
  const PassengerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              expandedHeight: 100,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              flexibleSpace: const FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alerts',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      Text('Live updates & notifications',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
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
                    _buildSection('Today', _todayAlerts, context),
                    const SizedBox(height: 24),
                    _buildSection('Earlier', _earlierAlerts, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _todayAlerts = [
    {
      'emoji': '🔵',
      'title': 'Bus 12A Approaching',
      'msg': 'Your bus is 500m away. Arriving in 2 min.',
      'time': '2 min ago',
      'type': 'approaching',
      'busId': 'bus_12a',
      'color': const Color(0xFFEFF6FF),
      'border': const Color(0xFF3B82F6),
    },
    {
      'emoji': '⚠️',
      'title': 'Traffic Delay – Bus 5B',
      'msg': 'Heavy traffic near RS Puram. Delay of 8–12 minutes expected.',
      'time': '14 min ago',
      'type': 'delay',
      'busId': 'bus_5b',
      'color': const Color(0xFFFEF3C7),
      'border': const Color(0xFFF59E0B),
    },
    {
      'emoji': '🚌',
      'title': 'Bus 24 On Time',
      'msg': 'Service running on schedule. Next bus in 9 min.',
      'time': '22 min ago',
      'type': 'info',
      'busId': 'bus_24',
      'color': const Color(0xFFF0FDF4),
      'border': const Color(0xFF22C55E),
    },
  ];

  static final _earlierAlerts = [
    {
      'emoji': '🔔',
      'title': 'Service Update – Route 88',
      'msg': 'Additional buses added on Route 88 during peak hours.',
      'time': '2 hr ago',
      'type': 'update',
      'busId': 'bus_88',
      'color': const Color(0xFFF8FAFC),
      'border': const Color(0xFFCBD5E1),
    },
    {
      'emoji': '🔴',
      'title': 'Bus 20C Not Running',
      'msg': 'Service suspended on Route 20C today due to maintenance.',
      'time': '4 hr ago',
      'type': 'disruption',
      'busId': 'bus_20c',
      'color': const Color(0xFFFFF1F2),
      'border': const Color(0xFFEF4444),
    },
    {
      'emoji': '⭐',
      'title': 'Route 12A – High Demand',
      'msg': 'Buses filling up quickly on Route 12A. Book your seat early.',
      'time': '6 hr ago',
      'type': 'info',
      'busId': 'bus_12a',
      'color': const Color(0xFFF5F3FF),
      'border': const Color(0xFF8B5CF6),
    },
  ];

  Widget _buildSection(
      String label,
      List<Map<String, dynamic>> alerts,
      BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B))),
        ),
        ...alerts.map((a) => _buildAlertCard(a, context)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> a, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: a['color'] as Color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (a['border'] as Color).withAlpha(80), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final busId = a['busId'] as String?;
          if (busId != null) {
            context.go('/passenger/live-tracking/$busId');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['emoji'] as String,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            a['title'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                fontSize: 14),
                          ),
                        ),
                        Text(
                          a['time'] as String,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['msg'] as String,
                      style: const TextStyle(
                          color: Color(0xFF475569), fontSize: 13),
                    ),
                    if (a['type'] == 'approaching') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Track Live',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
