import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel> loginWithOtp(String phone, String otp) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    _currentUser = UserModel(
      id: 'p1',
      name: 'John Passenger',
      email: 'passenger@easygo.com',
      phone: phone, // Use the entered phone number
      role: UserRole.passenger,
    );
    
    return _currentUser!;
  }

  @override
  Future<UserModel> driverLogin(String driverId, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    _currentUser = const UserModel(
      id: 'd1',
      name: 'Suresh Kumar',
      email: 'driver@easygo.com',
      phone: '+919876543211',
      role: UserRole.driver,
      assignedBusId: 'bus_102',
      assignedRouteId: 'route_12',
    );
    
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser;
  }
}
