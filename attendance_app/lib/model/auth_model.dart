import 'package:attendance_app/services/auth_services.dart';
import 'package:attendance_app/services/network_services.dart';
import 'package:attendance_app/services/storage_services.dart';
import '../core/errors/server_execption.dart';
import 'teacher_model.dart';

class AuthModel {
  final AuthService _authService;
  final StorageService _storageService;
  final NetworkService _networkService;

  AuthModel({
    required AuthService authService,
    required StorageService storageService,
    required NetworkService networkService,
  }) : _authService = authService,
       _storageService = storageService,
       _networkService = networkService;

  /// Login with passkey
  Future<Teacher?> verifyPasskey(String passkey) async {
    try {
      final isSetupComplete = await _storageService.isSetupComplete();

      // First time login needs internet
      if (!isSetupComplete) {
        return await _handleFirstTimeLogin(passkey);
      }

      // Subsequent login can work offline
      return await _handleSubsequentLogin(passkey);
    } catch (e) {
      rethrowWithAppropriateException(e);
      return null; // Won't reach here, just for compiler
    }
  }

  /// First time login requires internet
  Future<Teacher?> _handleFirstTimeLogin(String passkey) async {
    final isConnected = await _networkService.isConnected();
    if (!isConnected) {
      throw NetworkException(
        message: 'Internet connection required for first login',
      );
    }

    // Verify with server
    final teacher = await _authService.verifyTeacherPasskey(passkey);

    // Cache data for offline use
    if (teacher != null) {
      await _storageService.cacheAuthData(teacher, passkey);
    }

    return teacher;
  }

  /// Subsequent login can work offline
  Future<Teacher?> _handleSubsequentLogin(String passkey) async {
    // Validate passkey against stored hash
    final isValidPasskey = await _storageService.validatePasskey(passkey);
    if (!isValidPasskey) {
      throw AuthException(message: 'Invalid passkey');
    }

    // Get cached teacher data
    final cachedTeacher = await _storageService.getCachedTeacher();
    if (cachedTeacher == null) {
      throw CacheException(message: 'Cached auth data not found');
    }

    // Try to sync with server if online
    final isConnected = await _networkService.isConnected();
    if (isConnected) {
      try {
        final remoteTeacher = await _authService.verifyTeacherPasskey(passkey);
        if (remoteTeacher != null) {
          await _storageService.cacheAuthData(remoteTeacher, passkey);
          return remoteTeacher;
        }
      } catch (_) {
        // Allow offline login if server sync fails
      }
    }

    return cachedTeacher;
  }

  /// Logout the current user
  Future<void> logout() async {
    await _storageService.clearAuthData();
  }

  /// Check if user is logged in
  Future<Teacher?> checkAuthStatus() async {
    final isSetupComplete = await _storageService.isSetupComplete();
    if (!isSetupComplete) {
      return null;
    }

    final cachedTeacher = await _storageService.getCachedTeacher();
    if (cachedTeacher == null) {
      return null;
    }

    // Verify token if online
    final isConnected = await _networkService.isConnected();
    if (isConnected) {
      try {
        final isValid = await _authService.verifyToken(cachedTeacher.token);
        if (!isValid) {
          await logout();
          return null;
        }
      } catch (_) {
        // Continue with cached data if server check fails
      }
    }

    return cachedTeacher;
  }

  /// Convert and rethrow exceptions with appropriate type
  void rethrowWithAppropriateException(dynamic exception) {
    if (exception is ServerException ||
        exception is AuthException ||
        exception is CacheException ||
        exception is NetworkException) {
      throw exception;
    } else {
      throw ServerException(message: exception.toString());
    }
  }
}
