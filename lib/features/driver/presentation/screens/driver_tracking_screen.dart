import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/providers/trip_providers.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../domain/models/trip_model.dart';
import '../../../tracking/domain/models/bus_location_model.dart';

class DriverTrackingScreen extends ConsumerStatefulWidget {
  const DriverTrackingScreen({super.key});

  @override
  ConsumerState<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends ConsumerState<DriverTrackingScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final currentTripAsync = ref.watch(currentTripProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
      ),
      body: currentTripAsync.when(
        data: (trip) {
          if (trip == null || trip.status != TripStatus.active || user?.assignedBusId == null) {
            return const Center(child: Text('Start a trip to begin tracking.'));
          }

          final locationStream = ref.watch(busLocationStreamProvider(user!.assignedBusId!));

          return Column(
            children: [
              _buildStatusHeader(true),
              Expanded(
                child: locationStream.when(
                  data: (location) => _buildMap(location),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (user?.assignedBusId != null) {
            ref.read(locationSimulationControllerProvider).startSimulation(user!.assignedBusId!, "route_12");
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulation Started')));
          }
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  Widget _buildStatusHeader(bool isActive) {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(Icons.gps_fixed, 'GPS', 'Connected', Colors.green),
          _buildStatusItem(Icons.wifi, 'Internet', 'Connected', Colors.green),
          _buildStatusItem(
            Icons.track_changes, 
            'Tracking', 
            isActive ? 'Active' : 'Inactive', 
            isActive ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildMap(BusLocationModel location) {
    final latLng = LatLng(location.latitude, location.longitude);
    
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(latLng));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: latLng,
        zoom: 16.0,
      ),
      onMapCreated: (controller) => _mapController = controller,
      markers: {
        Marker(
          markerId: MarkerId(location.busId),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: location.heading,
        ),
      },
    );
  }
}
