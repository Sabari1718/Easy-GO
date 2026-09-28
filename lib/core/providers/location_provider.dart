import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';

class LocationState extends Equatable {
  final LocationPermission permissionStatus;
  final Position? currentPosition;
  final String? address;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.permissionStatus = LocationPermission.denied,
    this.currentPosition,
    this.address,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    LocationPermission? permissionStatus,
    Position? currentPosition,
    String? address,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      currentPosition: currentPosition ?? this.currentPosition,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isLocationEnabled => 
    permissionStatus == LocationPermission.always || 
    permissionStatus == LocationPermission.whileInUse;

  @override
  List<Object?> get props => [permissionStatus, currentPosition, address, isLoading, error];
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    Future.microtask(() => checkPermissionAndFetch());
    return const LocationState();
  }

  Future<void> checkPermissionAndFetch() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location services are disabled.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      state = state.copyWith(permissionStatus: permission);

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        await _fetchCurrentLocation();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      state = state.copyWith(permissionStatus: permission);

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        await _fetchCurrentLocation();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      String address = "Unknown Location";
      try {
        final geocoding = Geocoding();
        List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // E.g., "Gandhipuram, Coimbatore"
          String area = place.subLocality ?? place.thoroughfare ?? place.name ?? '';
          String city = place.locality ?? place.subAdministrativeArea ?? '';
          
          if (area.isNotEmpty && city.isNotEmpty) {
            address = '$area, $city';
          } else if (area.isNotEmpty) {
            address = area;
          } else if (city.isNotEmpty) {
            address = city;
          } else {
            address = 'Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}';
          }
        }
      } catch (e) {
        print("Geocoding Error: $e");
        // Fallback to coordinates if geocoding fails (common on emulators)
        address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      state = state.copyWith(
        currentPosition: position,
        address: address,
        isLoading: false,
      );
    } catch (e) {
      print("Location Error: $e");
      state = state.copyWith(isLoading: false, error: 'Failed to get location');
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(() {
  return LocationNotifier();
});
