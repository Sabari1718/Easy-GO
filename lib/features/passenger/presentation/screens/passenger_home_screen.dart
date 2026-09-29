import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/widgets/premium_card.dart';

import '../../../../core/providers/location_provider.dart';
import '../../data/repositories/mock_bus_repository.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<BusModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasPromptedLocation = false;
  final _storage = const FlutterSecureStorage();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initPromptFlag();
  }

  Future<void> _initPromptFlag() async {
    final prompted = await _storage.read(key: 'has_prompted_location');
    if (mounted) {
      setState(() {
        _hasPromptedLocation = prompted == 'true';
      });
    }
  }

  void _showLocationPermissionPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Turn On Location', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Enable your location to find buses near you and show your current location.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(locationProvider.notifier).requestPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enable Location'),
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isNotEmpty) {
      final repo = ref.read(mockBusRepositoryProvider);
      final results = await repo.searchBuses(query);
      if (mounted && _searchQuery == query) {
        setState(() => _searchResults = results);
      }
    }
  }

  void _showLocationBottomSheet(BuildContext context, LocationState locationState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationState.isLocationEnabled ? (locationState.address ?? 'Locating...') : 'Location Disabled',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (locationState.isLocationEnabled)
                          const Text(
                            'Tamil Nadu, India',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!locationState.isLocationEnabled) {
                      ref.read(locationProvider.notifier).requestPermission();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    locationState.isLocationEnabled ? 'Change Location' : 'Enable Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    ref.listen<LocationState>(locationProvider, (previous, next) async {
      if (next.currentPosition != null && _mapController != null) {
        if (previous?.currentPosition == null) {
          _mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(next.currentPosition!.latitude, next.currentPosition!.longitude),
              zoom: 15.0,
            ),
          ));
        } else {
           // Smooth update if map is already active
        }
      }

      if (next.isPermissionChecked && !next.isLocationEnabled) {
        if (!_hasPromptedLocation && next.permissionStatus != LocationPermission.deniedForever) {
          _hasPromptedLocation = true;
          await _storage.write(key: 'has_prompted_location', value: 'true');
          if (mounted) {
            _showLocationPermissionPrompt();
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Ultra Premium App Bar
            SliverAppBar(
              backgroundColor: const Color(0xFF0F172A),
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black.withAlpha(50),
              pinned: true,
              automaticallyImplyLeading: false,
              titleSpacing: 24,
              toolbarHeight: 90,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showLocationBottomSheet(context, locationState),
                      child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Current Location',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      locationState.isLocationEnabled 
                                        ? (locationState.address ?? 'Locating...') 
                                        : 'Location Disabled',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white70),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://ui-avatars.com/api/?name=User&background=fff&color=0F172A'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: Colors.white.withAlpha(50), width: 2),
                    ),
                  ),
                ],
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good Morning 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Where are you going?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Search Bar
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search buses, routes or stops',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Content
                    if (_isSearching)
                      _buildSearchResults()
                    else
                      _buildHomeContent(locationState),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No results found.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        ..._searchResults.map((bus) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildBusCard(bus, null),
        )),
      ],
    );
  }

  Widget _buildHomeContent(LocationState locationState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locationState.isLocationEnabled && locationState.currentPosition != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: PremiumCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(locationState.currentPosition!.latitude, locationState.currentPosition!.longitude),
                      zoom: 15.0,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: {
                      Marker(
                        markerId: const MarkerId('user_location'),
                        position: LatLng(locationState.currentPosition!.latitude, locationState.currentPosition!.longitude),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        infoWindow: const InfoWindow(title: 'Your Location'),
                      ),
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
            ),
          ),
          
        // Nearby Buses Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Buses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (locationState.isLocationEnabled)
              const Text(
                'View All →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (!locationState.isLocationEnabled)
          PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.location_disabled_rounded, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                const Text(
                  'Location is disabled',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Text(
                  locationState.permissionStatus == LocationPermission.deniedForever
                      ? 'Location permission is disabled.'
                      : 'Enable location to discover buses near you.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (locationState.permissionStatus == LocationPermission.deniedForever) {
                      Geolocator.openAppSettings();
                    } else {
                      ref.read(locationProvider.notifier).requestPermission();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(locationState.permissionStatus == LocationPermission.deniedForever ? 'Open Settings' : 'Enable Location'),
                ),
              ],
            ),
          )
        else if (locationState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF0F172A)),
            ),
          )
        else
          FutureBuilder<List<BusModel>>(
            future: ref.read(mockBusRepositoryProvider).getNearbyBuses(locationState.currentPosition),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        Text('🚌', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 16),
                        Text('No buses nearby', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        SizedBox(height: 8),
                        Text('Try searching for a route or bus stop.', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: snapshot.data!.map((bus) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildBusCard(bus, locationState.currentPosition),
                )).toList(),
              );
            },
          ),
          
        const SizedBox(height: 32),
        
        // Nearby Bus Stops
        const Text(
          'Nearby Bus Stops',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStopItem('Gandhipuram', '2.1 km'),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildStopItem('Town Hall', '3.4 km'),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        const Text(
          'Popular Routes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildRouteChip('Route 5'),
            _buildRouteChip('Route 12'),
            _buildRouteChip('Route 20'),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBusCard(BusModel bus, Position? userPos) {
    String distanceStr = '';
    if (userPos != null) {
      double dist = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, bus.latitude, bus.longitude);
      distanceStr = '${(dist / 1000).toStringAsFixed(1)} km away';
    }

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('BUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Text(
                  bus.busNumber,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route ${bus.route}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                if (distanceStr.isNotEmpty)
                  Text(
                    distanceStr,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ETA ${bus.eta}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF22C55E)),
              ),
              const SizedBox(height: 4),
              Text(
                bus.status,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopItem(String name, String distance) {
    return Row(
      children: [
        const Icon(Icons.location_on_rounded, color: Color(0xFF94A3B8), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          ),
        ),
        Text(
          distance,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildRouteChip(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus_rounded, color: Color(0xFF0F172A), size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}
