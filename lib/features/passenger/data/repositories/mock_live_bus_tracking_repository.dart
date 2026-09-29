import 'dart:async';
import 'dart:math';
import '../../domain/models/bus_live_state.dart';
import '../../domain/repositories/live_bus_tracking_repository.dart';
import '../services/mock_live_bus_service.dart';

class MockLiveBusTrackingRepository implements LiveBusTrackingRepository {
  static final MockLiveBusTrackingRepository _instance =
      MockLiveBusTrackingRepository._internal();
  factory MockLiveBusTrackingRepository() => _instance;

  MockLiveBusTrackingRepository._internal() {
    _initRouteData();
    _startSimulationTimer('bus_12a');
  }

  // ─── Polyline Coordinates for Ukkadam → Pollachi (Road path) ───────────────
  static final List<LatLngPoint> ukkadamPollachiPolyline = [
    // 1. Ukkadam (Bus Stand) - Index 0
    const LatLngPoint(10.9902, 76.9607),
    const LatLngPoint(10.9875, 76.9598),
    const LatLngPoint(10.9840, 76.9582),
    const LatLngPoint(10.9805, 76.9568),
    const LatLngPoint(10.9770, 76.9552),
    const LatLngPoint(10.9730, 76.9535),
    const LatLngPoint(10.9690, 76.9520),
    const LatLngPoint(10.9645, 76.9505),
    const LatLngPoint(10.9610, 76.9495),
    // 2. Sundakkamuthur - Index 9
    const LatLngPoint(10.9572, 76.9485),
    const LatLngPoint(10.9520, 76.9490),
    const LatLngPoint(10.9470, 76.9502),
    const LatLngPoint(10.9415, 76.9520),
    const LatLngPoint(10.9360, 76.9538),
    const LatLngPoint(10.9300, 76.9555),
    const LatLngPoint(10.9235, 76.9572),
    const LatLngPoint(10.9170, 76.9588),
    const LatLngPoint(10.9100, 76.9598),
    // 3. Madukkarai - Index 18
    const LatLngPoint(10.9038, 76.9602),
    const LatLngPoint(10.9035, 76.9540),
    const LatLngPoint(10.9030, 76.9470),
    const LatLngPoint(10.9025, 76.9400),
    const LatLngPoint(10.9018, 76.9320),
    const LatLngPoint(10.9010, 76.9240),
    const LatLngPoint(10.9002, 76.9160),
    const LatLngPoint(10.8994, 76.9090),
    // 4. Ettimadai - Index 26
    const LatLngPoint(10.8986, 76.9030),
    const LatLngPoint(10.8992, 76.9110),
    const LatLngPoint(10.9000, 76.9200),
    const LatLngPoint(10.9010, 76.9310),
    const LatLngPoint(10.9020, 76.9430),
    const LatLngPoint(10.9030, 76.9540),
    const LatLngPoint(10.9035, 76.9630),
    const LatLngPoint(10.9030, 76.9690),
    // 5. Karpagam - Index 34
    const LatLngPoint(10.9022, 76.9744),
    const LatLngPoint(10.8960, 76.9780),
    const LatLngPoint(10.8890, 76.9825),
    const LatLngPoint(10.8810, 76.9875),
    const LatLngPoint(10.8730, 76.9925),
    const LatLngPoint(10.8640, 76.9975),
    const LatLngPoint(10.8540, 77.0030),
    const LatLngPoint(10.8440, 77.0080),
    const LatLngPoint(10.8340, 77.0125),
    const LatLngPoint(10.8250, 77.0165),
    // 6. Kinathukadavu - Index 44
    const LatLngPoint(10.8174, 77.0194),
    const LatLngPoint(10.8260, 77.0160),
    const LatLngPoint(10.8370, 77.0110),
    const LatLngPoint(10.8490, 77.0050),
    const LatLngPoint(10.8620, 76.9980),
    const LatLngPoint(10.8760, 76.9910),
    const LatLngPoint(10.8900, 76.9840),
    const LatLngPoint(10.9040, 76.9790),
    const LatLngPoint(10.9180, 76.9750),
    // 7. Eachanari - Index 53
    const LatLngPoint(10.9328, 76.9701),
    const LatLngPoint(10.9200, 76.9740),
    const LatLngPoint(10.9050, 76.9785),
    const LatLngPoint(10.8880, 76.9840),
    const LatLngPoint(10.8700, 76.9910),
    const LatLngPoint(10.8500, 76.9990),
    const LatLngPoint(10.8300, 77.0110),
    const LatLngPoint(10.8100, 77.0190),
    const LatLngPoint(10.7850, 77.0220),
    const LatLngPoint(10.7600, 77.0210),
    const LatLngPoint(10.7350, 77.0195),
    const LatLngPoint(10.7100, 77.0175),
    const LatLngPoint(10.6850, 77.0140),
    const LatLngPoint(10.6700, 77.0115),
    // 8. Pollachi - Index 67
    const LatLngPoint(10.6588, 77.0090),
  ];

  static final List<RouteStop> ukkadamPollachiStops = [
    const RouteStop(id: 's1', name: 'Ukkadam', lat: 10.9902, lng: 76.9607),
    const RouteStop(id: 's2', name: 'Sundakkamuthur', lat: 10.9572, lng: 76.9485),
    const RouteStop(id: 's3', name: 'Madukkarai', lat: 10.9038, lng: 76.9602),
    const RouteStop(id: 's4', name: 'Ettimadai', lat: 10.8986, lng: 76.9030),
    const RouteStop(id: 's5', name: 'Karpagam', lat: 10.9022, lng: 76.9744),
    const RouteStop(id: 's6', name: 'Kinathukadavu', lat: 10.8174, lng: 77.0194),
    const RouteStop(id: 's7', name: 'Eachanari', lat: 10.9328, lng: 76.9701),
    const RouteStop(id: 's8', name: 'Pollachi', lat: 10.6588, lng: 77.0090),
  ];

  static const List<int> stopPolylineIndices = [0, 9, 18, 26, 34, 44, 53, 67];

  // ─── Simulation State ───────────────────────────────────────────────────────
  final Map<String, StreamController<BusLiveState>> _streamControllers = {};
  final Map<String, Timer> _simulationTimers = {};
  final Map<String, BusLiveState> _currentState = {};

  // Simulation internal parameters for bus_12a
  double _routeProgressFloat = 18.0; // Starts near Madukkarai for immediate lively demo
  BusJourneyStatus _simStatus = BusJourneyStatus.moving;
  int _dwellRemainingSeconds = 0;
  bool _isPaused = false;
  double _speedMultiplier = 1.0;
  String? _selectedStopId;
  String? _selectedStopName;
  late double _totalRouteDistanceKm;
  final List<double> _cumulativeDistances = [];

  void _initRouteData() {
    _cumulativeDistances.clear();
    _cumulativeDistances.add(0.0);
    double dist = 0.0;
    for (int i = 0; i < ukkadamPollachiPolyline.length - 1; i++) {
      final p1 = ukkadamPollachiPolyline[i];
      final p2 = ukkadamPollachiPolyline[i + 1];
      dist += _haversine(p1.lat, p1.lng, p2.lat, p2.lng);
      _cumulativeDistances.add(dist);
    }
    _totalRouteDistanceKm = dist;
  }

  @override
  Stream<BusLiveState> watchBus(String busId) {
    if (!_streamControllers.containsKey(busId)) {
      _streamControllers[busId] = StreamController<BusLiveState>.broadcast();
      _startSimulationTimer(busId);
    }
    // Emit immediate current state
    final current = _computeLiveState(busId);
    _currentState[busId] = current;
    scheduleMicrotask(() {
      if (_streamControllers[busId]?.isClosed == false) {
        _streamControllers[busId]?.add(current);
      }
    });
    return _streamControllers[busId]!.stream;
  }

  @override
  Future<BusLiveState> getCurrentBusState(String busId) async {
    return _computeLiveState(busId);
  }

  @override
  void selectPassengerStop(String busId, String? stopId) {
    _selectedStopId = stopId;
    if (stopId != null) {
      final stop = ukkadamPollachiStops.firstWhere(
        (s) => s.id == stopId,
        orElse: () => ukkadamPollachiStops.last,
      );
      _selectedStopName = stop.name;
    } else {
      _selectedStopName = null;
    }
    _emit(busId);
  }

  @override
  void startBus(String busId) {
    _isPaused = false;
    _emit(busId);
  }

  @override
  void pauseBus(String busId) {
    _isPaused = true;
    _emit(busId);
  }

  @override
  void resumeBus(String busId) {
    _isPaused = false;
    _emit(busId);
  }

  @override
  void skipToNextStop(String busId) {
    // Find next stop index
    int nextStopIdx = 0;
    for (int i = 0; i < stopPolylineIndices.length; i++) {
      if (stopPolylineIndices[i] > _routeProgressFloat.floor()) {
        nextStopIdx = i;
        break;
      }
    }
    if (nextStopIdx < stopPolylineIndices.length) {
      _routeProgressFloat = stopPolylineIndices[nextStopIdx].toDouble();
      if (nextStopIdx == stopPolylineIndices.length - 1) {
        _simStatus = BusJourneyStatus.serviceEnded;
      } else {
        _simStatus = BusJourneyStatus.stoppedAtStop;
        _dwellRemainingSeconds = 15;
      }
      _emit(busId);
    }
  }

  @override
  void resetJourney(String busId) {
    _routeProgressFloat = 0.0;
    _simStatus = BusJourneyStatus.moving;
    _dwellRemainingSeconds = 0;
    _isPaused = false;
    _emit(busId);
  }

  @override
  void setSpeedMultiplier(String busId, double multiplier) {
    _speedMultiplier = multiplier;
    _emit(busId);
  }

  void _startSimulationTimer(String busId) {
    _simulationTimers[busId]?.cancel();
    // Ticks every 1000ms (1 second) for smooth movement & countdown
    _simulationTimers[busId] =
        Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (_isPaused) return;
      _tickSimulation(busId);
    });
  }

  void _tickSimulation(String busId) {
    final maxIdx = ukkadamPollachiPolyline.length - 1;

    // Check if journey ended
    if (_routeProgressFloat >= maxIdx) {
      _simStatus = BusJourneyStatus.serviceEnded;
      _emit(busId);
      return;
    }

    if (_simStatus == BusJourneyStatus.stoppedAtStop) {
      // Countdown dwell timer
      _dwellRemainingSeconds -= (1 * _speedMultiplier).round();
      if (_dwellRemainingSeconds <= 0) {
        _dwellRemainingSeconds = 0;
        _simStatus = BusJourneyStatus.moving;
        // Step slightly forward to leave the stop
        _routeProgressFloat += 0.08 * _speedMultiplier;
      }
      _emit(busId);
      return;
    }

    // Bus is moving or approaching
    // Advance progress smoothly
    final step = 0.12 * _speedMultiplier;
    _routeProgressFloat += step;

    if (_routeProgressFloat >= maxIdx) {
      _routeProgressFloat = maxIdx.toDouble();
      _simStatus = BusJourneyStatus.serviceEnded;
      _emit(busId);
      return;
    }

    // Check next stop
    int nextStopIdx = 0;
    for (int i = 0; i < stopPolylineIndices.length; i++) {
      if (stopPolylineIndices[i] >= _routeProgressFloat) {
        nextStopIdx = i;
        break;
      }
    }

    final nextStopPolyIdx = stopPolylineIndices[nextStopIdx];
    final distanceToNextStopKm =
        _getDistanceBetweenProgress(_routeProgressFloat, nextStopPolyIdx.toDouble());

    // Check if reached stop
    if (_routeProgressFloat >= nextStopPolyIdx || distanceToNextStopKm < 0.05) {
      _routeProgressFloat = nextStopPolyIdx.toDouble();
      if (nextStopIdx == stopPolylineIndices.length - 1) {
        _simStatus = BusJourneyStatus.serviceEnded;
      } else {
        _simStatus = BusJourneyStatus.stoppedAtStop;
        _dwellRemainingSeconds = 15;
      }
    } else if (distanceToNextStopKm <= 0.6) {
      _simStatus = BusJourneyStatus.approachingStop;
    } else {
      _simStatus = BusJourneyStatus.moving;
    }

    _emit(busId);
  }

  BusLiveState _computeLiveState(String busId) {
    final maxIdx = ukkadamPollachiPolyline.length - 1;
    final clampedProgress = _routeProgressFloat.clamp(0.0, maxIdx.toDouble());
    final int idx = clampedProgress.floor().clamp(0, maxIdx - 1);
    final double t = (clampedProgress - idx).clamp(0.0, 1.0);

    final p1 = ukkadamPollachiPolyline[idx];
    final p2 = ukkadamPollachiPolyline[idx + 1];

    final currentLat = p1.lat + (p2.lat - p1.lat) * t;
    final currentLng = p1.lng + (p2.lng - p1.lng) * t;
    final heading = _bearing(p1.lat, p1.lng, p2.lat, p2.lng);

    // Stops determination
    int currentStopIdx = 0;
    int nextStopIdx = 1;
    for (int i = 0; i < stopPolylineIndices.length; i++) {
      if (stopPolylineIndices[i] <= clampedProgress) {
        currentStopIdx = i;
      }
      if (stopPolylineIndices[i] > clampedProgress) {
        nextStopIdx = i;
        break;
      }
    }
    if (nextStopIdx <= currentStopIdx) {
      nextStopIdx = (currentStopIdx + 1).clamp(0, ukkadamPollachiStops.length - 1);
    }

    final currentStop = ukkadamPollachiStops[currentStopIdx];
    final nextStop = ukkadamPollachiStops[nextStopIdx];

    // Distances
    final distanceTravelledKm =
        _cumulativeDistances[idx] + _haversine(p1.lat, p1.lng, currentLat, currentLng);
    final distanceRemainingKm =
        (_totalRouteDistanceKm - distanceTravelledKm).clamp(0.0, _totalRouteDistanceKm);
    final distanceToNextStopKm = _getDistanceBetweenProgress(
        clampedProgress, stopPolylineIndices[nextStopIdx].toDouble());

    // Progress percentage
    final progressPct = (_totalRouteDistanceKm > 0)
        ? ((distanceTravelledKm / _totalRouteDistanceKm) * 100).clamp(0.0, 100.0)
        : 0.0;

    // Speed calculation
    double speedKmh = 0.0;
    if (_simStatus == BusJourneyStatus.moving) {
      speedKmh = 38.0 + (sin(clampedProgress * 3) * 6.0);
    } else if (_simStatus == BusJourneyStatus.approachingStop) {
      speedKmh = 16.0 + (cos(clampedProgress * 4) * 3.0);
    } else {
      speedKmh = 0.0;
    }

    // ETA calculation (based on speed & stop dwell times)
    final remainingStopsCount =
        (ukkadamPollachiStops.length - 1) - currentStopIdx;
    final travelTimeMinutes =
        (distanceRemainingKm / (speedKmh > 10 ? speedKmh : 30.0)) * 60;
    final dwellTimeTotalMinutes = remainingStopsCount * 0.5;
    final totalEtaMinutes =
        (travelTimeMinutes + dwellTimeTotalMinutes).ceil().clamp(1, 120);

    // Status message
    String statusMessage = '';
    switch (_simStatus) {
      case BusJourneyStatus.notStarted:
        statusMessage = 'Bus at Ukkadam • Ready to depart';
        break;
      case BusJourneyStatus.moving:
        if (currentStopIdx == 0) {
          statusMessage = 'Left ${currentStop.name} • Moving to ${nextStop.name}';
        } else {
          statusMessage = 'Left ${currentStop.name} • Moving to ${nextStop.name}';
        }
        break;
      case BusJourneyStatus.approachingStop:
        final meters = (distanceToNextStopKm * 1000).round();
        statusMessage = 'Approaching ${nextStop.name} ($meters m away)';
        break;
      case BusJourneyStatus.stoppedAtStop:
        statusMessage = 'Bus stopped at ${currentStop.name}';
        break;
      case BusJourneyStatus.serviceEnded:
        statusMessage = '🏁 Journey Completed • Reached Pollachi';
        break;
    }

    // Passenger selected stop calculations
    double? distToSelected;
    int? etaToSelected;
    int? stopsToSelected;

    if (_selectedStopId != null) {
      final selIndex = ukkadamPollachiStops
          .indexWhere((s) => s.id == _selectedStopId);
      if (selIndex >= 0) {
        stopsToSelected = (selIndex - currentStopIdx).clamp(0, 8);
        final selPolyIdx = stopPolylineIndices[selIndex];
        if (selPolyIdx >= clampedProgress) {
          distToSelected = _getDistanceBetweenProgress(
              clampedProgress, selPolyIdx.toDouble());
          final selTravelMin =
              (distToSelected / (speedKmh > 10 ? speedKmh : 30.0)) * 60;
          etaToSelected = (selTravelMin + (stopsToSelected * 0.5))
              .ceil()
              .clamp(0, 120);
        } else {
          distToSelected = 0.0;
          etaToSelected = 0;
        }
      }
    }

    return BusLiveState(
      busId: busId,
      busNumber: '12A',
      routeId: 'r12a_ukkadam_pollachi',
      routeName: 'Ukkadam → Pollachi',
      latitude: currentLat,
      longitude: currentLng,
      speed: speedKmh,
      heading: heading,
      currentStopId: currentStop.id,
      currentStopName: currentStop.name,
      currentStopIndex: currentStopIdx,
      nextStopId: nextStop.id,
      nextStopName: nextStop.name,
      nextStopIndex: nextStopIdx,
      distanceToNextStop: distanceToNextStopKm,
      distanceTravelled: distanceTravelledKm,
      distanceRemaining: distanceRemainingKm,
      totalRouteDistance: _totalRouteDistanceKm,
      etaMinutes: totalEtaMinutes,
      progressPercentage: progressPct,
      status: _simStatus,
      statusMessage: statusMessage,
      lastUpdated: DateTime.now(),
      selectedStopId: _selectedStopId,
      selectedStopName: _selectedStopName,
      distanceToSelectedStop: distToSelected,
      etaToSelectedStop: etaToSelected,
      stopsToSelectedStop: stopsToSelected,
      isPaused: _isPaused,
      speedMultiplier: _speedMultiplier,
      currentRoutePointIndex: idx,
      dwellTimeRemainingSeconds: _dwellRemainingSeconds,
    );
  }

  double _getDistanceBetweenProgress(double pStart, double pEnd) {
    if (pStart >= pEnd) return 0.0;
    final int idx1 = pStart.floor().clamp(0, ukkadamPollachiPolyline.length - 1);
    final int idx2 = pEnd.floor().clamp(0, ukkadamPollachiPolyline.length - 1);
    final dist = _cumulativeDistances[idx2] - _cumulativeDistances[idx1];
    return dist.abs();
  }

  void _emit(String busId) {
    final state = _computeLiveState(busId);
    _currentState[busId] = state;
    if (_streamControllers[busId]?.isClosed == false) {
      _streamControllers[busId]?.add(state);
    }
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _bearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * pi / 180;
    final lat1R = lat1 * pi / 180;
    final lat2R = lat2 * pi / 180;
    final y = sin(dLng) * cos(lat2R);
    final x =
        cos(lat1R) * sin(lat2R) - sin(lat1R) * cos(lat2R) * cos(dLng);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  void dispose() {
    for (final timer in _simulationTimers.values) {
      timer.cancel();
    }
    for (final ctrl in _streamControllers.values) {
      ctrl.close();
    }
  }
}
