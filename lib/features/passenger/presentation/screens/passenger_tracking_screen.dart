import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/providers/bus_providers.dart';
import '../../../../core/providers/route_providers.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../buses/domain/models/bus_model.dart';
import '../../../tracking/domain/models/bus_location_model.dart';

class PassengerTrackingScreen extends ConsumerStatefulWidget {
  const PassengerTrackingScreen({super.key});

  @override
  ConsumerState<PassengerTrackingScreen> createState() => _PassengerTrackingScreenState();
}

class _PassengerTrackingScreenState extends ConsumerState<PassengerTrackingScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    // For demo purposes, we'll watch a specific bus, e.g. bus_102
    final busId = 'bus_102';
    final locationStream = ref.watch(busLocationStreamProvider(busId));

    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: locationStream.when(
        data: (location) => _buildMap(location, busId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMap(BusLocationModel location, String busId) {
    final latLng = LatLng(location.latitude, location.longitude);
    
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(latLng));
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: latLng,
            zoom: 15.0,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: {
            Marker(
              markerId: MarkerId(location.busId),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              rotation: location.heading,
              onTap: () {
                _showBusDetailsSheet(context, ref, busId);
              },
            ),
          },
        ),
      ],
    );
  }

  void _showBusDetailsSheet(BuildContext context, WidgetRef ref, String busId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final busAsync = ref.watch(selectedBusProvider(busId));
            return busAsync.when(
              data: (bus) {
                final routeAsync = ref.watch(selectedRouteProvider(bus.routeId));
                
                return Container(
                  padding: const EdgeInsets.all(24),
                  height: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(bus.busNumber, style: Theme.of(context).textTheme.headlineMedium),
                          StatusChip(status: bus.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      routeAsync.when(
                        data: (route) => Text('Route: ${route.routeNumber} - ${route.routeName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        loading: () => const Text('Loading route...'),
                        error: (_, __) => const Text('Route error'),
                      ),
                      const Divider(height: 32),
                      _buildInfoRow('Next Stop', 'Town Hall'), // Hardcoded next stop name for mock
                      const SizedBox(height: 16),
                      _buildInfoRow('ETA', '${bus.etaMinutes} mins'),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/passenger/bus/${bus.id}');
                          },
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
