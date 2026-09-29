import 'package:equatable/equatable.dart';

class BusStopInfo extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final List<StopArrivingBus> arrivingBuses;

  const BusStopInfo({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.arrivingBuses,
  });

  @override
  List<Object?> get props => [id, name, latitude, longitude, address, arrivingBuses];
}

class StopArrivingBus extends Equatable {
  final String busId;
  final String busNumber;
  final String destination;
  final int etaMinutes;
  final String status; // 'On Time', 'Approaching', 'Delayed'

  const StopArrivingBus({
    required this.busId,
    required this.busNumber,
    required this.destination,
    required this.etaMinutes,
    required this.status,
  });

  @override
  List<Object?> get props => [busId, busNumber, destination, etaMinutes, status];
}
