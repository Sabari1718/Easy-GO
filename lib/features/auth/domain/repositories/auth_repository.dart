import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> loginWithOtp(String phone, String otp);
  Future<UserModel> driverLogin(String driverId, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}
