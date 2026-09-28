import 'package:equatable/equatable.dart';

enum TripStatus { pending, active, completed }

class TripModel extends Equatable {
  final String id;
  final String driverId;
  final String busId;
  final String routeId;
  final TripStatus status;
  final DateTime? startTime;
  final DateTime? endTime;

  const TripModel({
    required this.id,
    required this.driverId,
    required this.busId,
    required this.routeId,
    required this.status,
    this.startTime,
    this.endTime,
  });

  TripModel copyWith({
    String? id,
    String? driverId,
    String? busId,
    String? routeId,
    TripStatus? status,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TripModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [id, driverId, busId, routeId, status, startTime, endTime];
}
