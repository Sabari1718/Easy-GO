import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';

class LocationState extends Equatable {
  final LocationPermission permissionStatus;
  final Position? currentPosition;
  final String? address;
  final bool isLoading;
  final String? error;
  final bool isPermissionChecked;

  const LocationState({
    this.permissionStatus = LocationPermission.denied,
    this.currentPosition,
    this.address,
    this.isLoading = false,
    this.error,
    this.isPermissionChecked = false,
  });

  LocationState copyWith({
    LocationPermission? permissionStatus,
    Position? currentPosition,
    String? address,
    bool? isLoading,
    String? error,
    bool? isPermissionChecked,
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      currentPosition: currentPosition ?? this.currentPosition,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPermissionChecked: isPermissionChecked ?? this.isPermissionChecked,
    );
  }

  bool get isLocationEnabled => 
    permissionStatus == LocationPermission.always || 
    permissionStatus == LocationPermission.whileInUse;

  @override
  List<Object?> get props => [permissionStatus, currentPosition, address, isLoading, error, isPermissionChecked];
}

class LocationNotifier extends Notifier<LocationState> {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastGeocodedPosition; // Track last position we actually reverse-geocoded

  @override
  LocationState build() {
    ref.onDispose(() {
      _positionStreamSubscription?.cancel();
    });
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
          isPermissionChecked: true,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      state = state.copyWith(
        permissionStatus: permission,
        isPermissionChecked: true,
      );

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        await _startLocationStream();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), isPermissionChecked: true);
    }
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      state = state.copyWith(permissionStatus: permission);

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        await _startLocationStream();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _startLocationStream() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _updatePositionAndAddress(position);

      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen(
        (Position newPosition) {
          _updatePositionAndAddress(newPosition);
        },
        onError: (e) {
          state = state.copyWith(error: 'Location stream error: $e');
        }
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to get location');
    }
  }

  Future<void> _updatePositionAndAddress(Position position) async {
    // Always update position immediately for real-time accuracy
    state = state.copyWith(
      currentPosition: position,
      isLoading: false,
    );

    // Only reverse-geocode if user moved significantly (saves battery & data).
    // Threshold: 100 m from last geocoded position.
    bool shouldGeocode = false;
    if (_lastGeocodedPosition == null) {
      shouldGeocode = true;
    } else {
      final distM = Geolocator.distanceBetween(
        _lastGeocodedPosition!.latitude,
        _lastGeocodedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      shouldGeocode = distM >= 100.0;
    }

    if (!shouldGeocode) return;
    _lastGeocodedPosition = position;

    String address = state.address ?? 'Unknown Location';
    try {
      final geocodingInstance = geocoding.Geocoding();
      final List<geocoding.Placemark> placemarks =
          await geocodingInstance.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final String area =
            place.subLocality ?? place.thoroughfare ?? place.name ?? '';
        final String city =
            place.locality ?? place.subAdministrativeArea ?? '';

        if (area.isNotEmpty && city.isNotEmpty) {
          address = '$area, $city';
        } else if (area.isNotEmpty) {
          address = area;
        } else if (city.isNotEmpty) {
          address = city;
        } else {
          address =
              'Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}';
        }
      }
    } catch (e) {
      address =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }

    // Only update state if geocoding actually produced a new address
    if (address != state.address) {
      state = state.copyWith(address: address);
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(() {
  return LocationNotifier();
});
