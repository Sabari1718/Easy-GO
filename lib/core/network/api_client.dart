import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

/// Placeholder for backend API integration.
/// DO NOT use this for frontend development yet, use Mock Repositories instead.
class ApiClient {
  final Dio _dio;
  final SecureStorageService _storage;

  ApiClient(this._storage)
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle error (e.g., refresh token on 401)
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
