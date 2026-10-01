import 'package:flutter/material.dart';
import '../../../../core/providers/location_provider.dart';

class EasyGoHeroHeader extends StatelessWidget {
  final LocationState locationState;
  final Animation<double> pulseAnimation;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const EasyGoHeroHeader({
    super.key,
    required this.locationState,
    required this.pulseAnimation,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  String _formatLocation(LocationState state) {
    if (!state.isLocationEnabled) {
      return 'Location disabled';
    }
    if (state.isLoading) {
      return 'Locating...';
    }
    final address = state.address?.trim();
    if (address != null && address.isNotEmpty) {
      return address;
    }
    return 'Gandhipuram, Coimbatore';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final locationName = _formatLocation(locationState);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 52),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // LEFT: Location hierarchy
            Expanded(
              child: InkWell(
                onTap: onLocationTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: pulseAnimation,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: locationState.isLocationEnabled
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              locationName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Current location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // RIGHT: Small profile avatar (circle button)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: InkWell(
                onTap: onProfileTap,
                customBorder: const CircleBorder(),
                child: const Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
