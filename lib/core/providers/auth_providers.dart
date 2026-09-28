import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/models/user_model.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() async {
    return _checkSession();
  }

  Future<UserModel?> _checkSession() async {
    final storage = ref.read(secureStorageProvider);
    final isLoggedIn = await storage.read(key: 'isLoggedIn');
    final mobileNumber = await storage.read(key: 'mobileNumber');

    if (isLoggedIn == 'true' && mobileNumber != null) {
      return UserModel(
        id: 'mock_id_1',
        name: 'Passenger',
        email: '',
        phone: mobileNumber,
        role: UserRole.passenger,
      );
    }
    return null;
  }

  Future<void> loginWithOtp(String phone, String otp) async {
    state = const AsyncValue.loading();
    try {
      if (otp == '123456') {
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: 'isLoggedIn', value: 'true');
        await storage.write(key: 'mobileNumber', value: phone);
        
        final user = UserModel(
          id: 'mock_id_1',
          name: 'Passenger',
          email: '',
          phone: phone,
          role: UserRole.passenger,
        );
        state = AsyncValue.data(user);
      } else {
        throw Exception('Invalid OTP');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> driverLogin(String driverId, String password) async {
    state = const AsyncValue.loading();
    try {
      // Mock driver login
      if (driverId.isNotEmpty && password.isNotEmpty) {
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: 'isLoggedIn', value: 'true');
        await storage.write(key: 'driverId', value: driverId);
        
        final user = UserModel(
          id: 'mock_driver_1',
          name: 'Driver $driverId',
          email: '',
          phone: '9999999999',
          role: UserRole.driver,
        );
        state = AsyncValue.data(user);
      } else {
        throw Exception('Invalid driver credentials');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.delete(key: 'isLoggedIn');
      await storage.delete(key: 'mobileNumber');
      await storage.delete(key: 'driverId');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value;
});
