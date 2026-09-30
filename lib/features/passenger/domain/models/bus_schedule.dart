class BusSchedule {
  final String id;
  final String routeId;
  final String busNumber;
  final String departureTime;
  final String arrivalTime;
  final List<String> daysOfWeek;
  final String status; // 'SCHEDULED', 'RUNNING', 'COMPLETED', 'DELAYED'
  final bool isLive;
  final String? currentStop;
  final int? etaMinutes;

  const BusSchedule({
    required this.id,
    required this.routeId,
    required this.busNumber,
    required this.departureTime,
    required this.arrivalTime,
    required this.daysOfWeek,
    required this.status,
    this.isLive = false,
    this.currentStop,
    this.etaMinutes,
  });

  factory BusSchedule.fromJson(Map<String, dynamic> json) {
    return BusSchedule(
      id: json['id'] as String? ?? '',
      routeId: json['routeId'] as String? ?? '',
      busNumber: json['busNumber'] as String? ?? '',
      departureTime: json['departureTime'] as String? ?? '',
      arrivalTime: json['arrivalTime'] as String? ?? '',
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      status: json['status'] as String? ?? 'SCHEDULED',
      isLive: json['isLive'] as bool? ?? false,
      currentStop: json['currentStop'] as String?,
      etaMinutes: json['etaMinutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'busNumber': busNumber,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'daysOfWeek': daysOfWeek,
        'status': status,
        'isLive': isLive,
        if (currentStop != null) 'currentStop': currentStop,
        if (etaMinutes != null) 'etaMinutes': etaMinutes,
      };
}
