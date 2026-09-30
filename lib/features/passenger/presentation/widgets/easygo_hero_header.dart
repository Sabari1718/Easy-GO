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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF080E1E),
            Color(0xFF0F172A),
            Color(0xFF131A32),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 52),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── TOP ROW: Location (Left) & Actions (Right) ──────────────────
            Row(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Small muted eyebrow with LIVE dot
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                scale: pulseAnimation,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: locationState.isLocationEnabled
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (locationState.isLocationEnabled
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF59E0B))
                                            .withAlpha(140),
                                        blurRadius: 5,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE LOCATION',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: Colors.white.withAlpha(160),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 3),

                          // Location Name with subtle downward chevron
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  locationName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 17,
                                color: Colors.white.withAlpha(170),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // RIGHT: Two compact circular action buttons (Notification & Profile)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Notification Button
                    _HeaderCircleButton(
                      onTap: onNotificationTap,
                      icon: Icons.notifications_none_rounded,
                      hasBadge: true,
                    ),

                    const SizedBox(width: 10),

                    // Profile Button
                    _HeaderCircleButton(
                      onTap: onProfileTap,
                      icon: Icons.person_outline_rounded,
                      hasBadge: false,
                    ),
                  ],
                ),
              ],
            ),

            // Proper breathing room between top row and headline (20px)
            const SizedBox(height: 20),

            // ── HEADLINE: Clean, Elegant Hero Greeting ──────────────────────
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.24,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'Where are you\n'),
                  TextSpan(
                    text: 'heading today?',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool hasBadge;

  const _HeaderCircleButton({
    required this.onTap,
    required this.icon,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(160),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withAlpha(30),
          highlightColor: Colors.white.withAlpha(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: Colors.white.withAlpha(220),
              ),
              if (hasBadge)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0F172A),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
