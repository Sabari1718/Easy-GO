import 'package:equatable/equatable.dart';

class BusLocationModel extends Equatable {
  final String busId;
  final double latitude;
  final double longitude;
  final double heading;

  const BusLocationModel({
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.heading,
  });

  @override
  List<Object?> get props => [busId, latitude, longitude, heading];
}
