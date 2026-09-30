import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/constants/api_constants.dart';
import '../../domain/models/bus_live_state.dart';
import '../../domain/repositories/live_bus_tracking_repository.dart';
import 'mock_live_bus_tracking_repository.dart';

class BackendLiveBusTrackingRepository implements LiveBusTrackingRepository {
  static final BackendLiveBusTrackingRepository _instance =
      BackendLiveBusTrackingRepository._internal();
  factory BackendLiveBusTrackingRepository() => _instance;

  final MockLiveBusTrackingRepository _fallbackRepo = MockLiveBusTrackingRepository();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 2),
    receiveTimeout: const Duration(seconds: 2),
  ));

  io.Socket? _socket;
  bool _isConnected = false;
  final Map<String, StreamController<BusLiveState>> _streamControllers = {};
  final Map<String, BusLiveState> _lastKnownStates = {};
  final Set<String> _activeSubscribedBuses = {};

  BackendLiveBusTrackingRepository._internal() {
    _initSocket();
  }

  void _initSocket() {
    try {
      final serverUrl = ApiConstants.baseUrl;
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('🔌 [WebSocket] Connected to EasyGo Backend Live Gateway');
        // Resubscribe active buses
        for (final busId in _activeSubscribedBuses) {
          _socket?.emit('subscribeToBus', {'busId': busId});
        }
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        debugPrint('🔌 [WebSocket] Disconnected from EasyGo Backend Live Gateway');
      });

      _socket?.onConnectError((err) {
        _isConnected = false;
        debugPrint('🔌 [WebSocket] Connection Error: $err');
      });

      // Listen for real-time location updates
      _socket?.on('bus.location.updated', (data) {
        if (data is Map) {
          _handleLiveUpdate(Map<String, dynamic>.from(data));
        }
      });
    } catch (e) {
      debugPrint('🔌 [WebSocket] Socket initialization error: $e');
    }
  }

  void _handleLiveUpdate(Map<String, dynamic> data) {
    try {
      final updatedState = BusLiveState.fromJson(data);
      final rawBusId = updatedState.busId;
      final busNumber = updatedState.busNumber.toLowerCase();

      // Dispatch to any matching stream controller
      for (final entry in _streamControllers.entries) {
        final key = entry.key.toLowerCase();
        final cleanKey = key.replaceAll('bus_', '').replaceAll('bus-', '');
        
        final matches = key == rawBusId.toLowerCase() ||
            cleanKey == busNumber ||
            key == 'bus_$busNumber' ||
            key == busNumber;

        if (matches && !entry.value.isClosed) {
          _lastKnownStates[entry.key] = updatedState;
          entry.value.add(updatedState);
        }
      }
    } catch (e) {
      debugPrint('Error processing live bus update: $e');
    }
  }

  @override
  Stream<BusLiveState> watchBus(String busId) {
    if (!_streamControllers.containsKey(busId) || _streamControllers[busId]!.isClosed) {
      _streamControllers[busId] = StreamController<BusLiveState>.broadcast();
    }

    _activeSubscribedBuses.add(busId);

    // If socket is connected, emit subscription
    if (_isConnected) {
      _socket?.emit('subscribeToBus', {'busId': busId});
    }

    // 1. Deliver cached state immediately if available
    final cached = _lastKnownStates[busId];
    if (cached != null) {
      scheduleMicrotask(() {
        if (_streamControllers[busId]?.isClosed == false) {
          _streamControllers[busId]?.add(cached);
        }
      });
    }

    // 2. Fetch latest live state via HTTP GET /buses/:busId/live
    _fetchInitialLiveState(busId);

    // 3. Fallback timer if backend is disconnected or offline
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_streamControllers[busId]?.isClosed != false) {
        timer.cancel();
        return;
      }
      if (!_isConnected) {
        // Use local fallback calculation when backend socket isn't connected
        _fallbackRepo.getCurrentBusState(busId).then((fallbackState) {
          if (_streamControllers[busId]?.isClosed == false) {
            _streamControllers[busId]?.add(fallbackState);
          }
        });
      }
    });

    return _streamControllers[busId]!.stream;
  }

  Future<void> _fetchInitialLiveState(String busId) async {
    try {
      final res = await _dio.get('${ApiConstants.baseUrl}/buses/$busId/live');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          final liveState = BusLiveState.fromJson(data);
          _lastKnownStates[busId] = liveState;
          if (_streamControllers[busId]?.isClosed == false) {
            _streamControllers[busId]?.add(liveState);
          }
        }
      }
    } catch (_) {
      // Fallback
      final fallbackState = await _fallbackRepo.getCurrentBusState(busId);
      if (_streamControllers[busId]?.isClosed == false && _lastKnownStates[busId] == null) {
        _streamControllers[busId]?.add(fallbackState);
      }
    }
  }

  @override
  Future<BusLiveState> getCurrentBusState(String busId) async {
    final cached = _lastKnownStates[busId];
    if (cached != null) return cached;

    try {
      final res = await _dio.get('${ApiConstants.baseUrl}/buses/$busId/live');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return BusLiveState.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}

    return _fallbackRepo.getCurrentBusState(busId);
  }

  @override
  void selectPassengerStop(String busId, String? stopId) {
    _fallbackRepo.selectPassengerStop(busId, stopId);
  }

  @override
  void startBus(String busId) {
    _fallbackRepo.startBus(busId);
    _socket?.emit('resumeSimulator', {'busId': busId});
  }

  @override
  void pauseBus(String busId) {
    _fallbackRepo.pauseBus(busId);
    _socket?.emit('pauseSimulator', {'busId': busId});
  }

  @override
  void resumeBus(String busId) {
    _fallbackRepo.resumeBus(busId);
    _socket?.emit('resumeSimulator', {'busId': busId});
  }

  @override
  void skipToNextStop(String busId) {
    _fallbackRepo.skipToNextStop(busId);
  }

  @override
  void resetJourney(String busId) {
    _fallbackRepo.resetJourney(busId);
  }

  @override
  void setSpeedMultiplier(String busId, double multiplier) {
    _fallbackRepo.setSpeedMultiplier(busId, multiplier);
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    for (final ctrl in _streamControllers.values) {
      ctrl.close();
    }
  }
}
