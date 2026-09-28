import 'package:equatable/equatable.dart';

enum BusStatus {
  onRoute,
  full,
  notFull,
  breakdown,
  offline,
}

class BusModel extends Equatable {
  final String id;
  final String busNumber;
  final String routeId;
  final BusStatus status;
  final String nextStopId;
  final int etaMinutes;

  const BusModel({
    required this.id,
    required this.busNumber,
    required this.routeId,
    required this.status,
    required this.nextStopId,
    required this.etaMinutes,
  });

  BusModel copyWith({
    String? id,
    String? busNumber,
    String? routeId,
    BusStatus? status,
    String? nextStopId,
    int? etaMinutes,
  }) {
    return BusModel(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      routeId: routeId ?? this.routeId,
      status: status ?? this.status,
      nextStopId: nextStopId ?? this.nextStopId,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }

  @override
  List<Object?> get props => [id, busNumber, routeId, status, nextStopId, etaMinutes];
}
