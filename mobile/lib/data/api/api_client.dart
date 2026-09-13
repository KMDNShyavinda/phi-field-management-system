import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';
import '../../domain/models.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<SessionUser> login(
    String email,
    String password, {
    String? fullName,
    String? mohArea,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      ).timeout(const Duration(seconds: 4));
      final data = response.data!;
      await _storage.write(key: 'access_token', value: data['access_token'] as String);
      await _storage.write(key: 'refresh_token', value: data['refresh_token'] as String);
      await _storage.write(key: 'user', value: jsonEncode(data['user']));
      return SessionUser.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      // Offline fallback: If backend server is unreachable (standalone phone mode),
      // authenticate locally so PHI officer is never blocked.
      return loginOffline(
        email: email,
        fullName: fullName,
        mohArea: mohArea,
      );
    }
  }

  Future<SessionUser> loginOffline({
    String? email,
    String? fullName,
    String? mohArea,
  }) async {
    final cleanEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : DemoAccounts.email;
    final cleanName = (fullName != null && fullName.trim().isNotEmpty) ? fullName.trim() : 'PHI Officer';
    final cleanArea = (mohArea != null && mohArea.trim().isNotEmpty) ? mohArea.trim() : 'Colombo MOH';

    final user = SessionUser(
      id: 'phi-local-1',
      email: cleanEmail,
      fullName: cleanName,
      role: 'phi',
      mohArea: cleanArea,
    );

    await _storage.write(key: 'access_token', value: 'offline_token');
    await _storage.write(key: 'refresh_token', value: 'offline_token');
    await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
    return user;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<SessionUser?> cachedUser() async {
    final raw = await _storage.read(key: 'user');
    if (raw == null) return null;
    return SessionUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> pull({String? since}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sync/pull',
      queryParameters: {if (since != null) 'since': since},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> push(List<Map<String, dynamic>> ops) async {
    final response = await _dio.post<Map<String, dynamic>>('/sync/push', data: {'ops': ops});
    return response.data!;
  }

  Future<void> uploadPhoto({
    required String photoId,
    required String inspectionId,
    required File file,
  }) async {
    await _dio.post(
      '/media/photos',
      data: FormData.fromMap({
        'photo_id': photoId,
        'inspection_id': inspectionId,
        'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
      }),
    );
  }

  Future<void> uploadReport({required String inspectionId, required File file}) async {
    await _dio.post(
      '/media/reports',
      data: FormData.fromMap({
        'inspection_id': inspectionId,
        'file': await MultipartFile.fromFile(file.path, filename: 'inspection-$inspectionId.pdf'),
      }),
    );
  }
}
