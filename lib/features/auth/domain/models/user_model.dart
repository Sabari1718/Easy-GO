import 'package:equatable/equatable.dart';

enum UserRole { passenger, driver, unknown }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? assignedBusId;
  final String? assignedRouteId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.assignedBusId,
    this.assignedRouteId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.unknown,
      ),
      assignedBusId: json['assignedBusId'] as String?,
      assignedRouteId: json['assignedRouteId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'assignedBusId': assignedBusId,
      'assignedRouteId': assignedRouteId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        assignedBusId,
        assignedRouteId,
      ];
}
