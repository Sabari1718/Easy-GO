import 'package:equatable/equatable.dart';

class BusStopModel extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const BusStopModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [id, name, latitude, longitude];
}

class RouteModel extends Equatable {
  final String id;
  final String routeNumber;
  final String routeName;
  final List<BusStopModel> stops;
  final List<String> activeBusIds;

  const RouteModel({
    required this.id,
    required this.routeNumber,
    required this.routeName,
    required this.stops,
    required this.activeBusIds,
  });

  @override
  List<Object?> get props => [id, routeNumber, routeName, stops, activeBusIds];
}
