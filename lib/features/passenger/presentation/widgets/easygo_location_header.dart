import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/location_provider.dart';

class EasyGoLocationHeader extends StatelessWidget {
  final LocationState locationState;
  final Animation<double> pulseAnimation;
  final VoidCallback onLocationTap;

  const EasyGoLocationHeader({
    super.key,
    required this.locationState,
    required this.pulseAnimation,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final addressText = locationState.isLocationEnabled
        ? (locationState.address ?? 'Locating current position...')
        : 'Location Disabled';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF090E1A),
            Color(0xFF131D33),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulse location pin button
              GestureDetector(
                onTap: onLocationTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: locationState.isLocationEnabled
                        ? const Color(0xFF10B981).withAlpha(30)
                        : const Color(0xFFEF4444).withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: locationState.isLocationEnabled
                          ? const Color(0xFF10B981).withAlpha(60)
                          : const Color(0xFFEF4444).withAlpha(60),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: pulseAnimation,
                      child: Icon(
                        locationState.isLocationEnabled
                            ? Icons.my_location_rounded
                            : Icons.location_off_rounded,
                        color: locationState.isLocationEnabled
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Location status & dynamic address
              Expanded(
                child: GestureDetector(
                  onTap: onLocationTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'YOUR LOCATION',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (locationState.isLocationEnabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE GPS',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        addressText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Notification button with frosted container
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/passenger/notifications'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withAlpha(25),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
