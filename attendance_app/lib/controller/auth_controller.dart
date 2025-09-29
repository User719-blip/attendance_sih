import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/errors/server_execption.dart';
import '../model/auth_model.dart';
import '../services/network_services.dart';
import '../model/teacher_model.dart';

class AuthController extends ChangeNotifier {
  final AuthModel _authModel;
  final NetworkService _networkService; // Add this

  Teacher? _currentTeacher;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isInitialized = false;

  AuthController(this._authModel, this._networkService); // Update constructor

  // Getters
  Teacher? get currentTeacher => _currentTeacher;
  bool get isAuthenticated => _currentTeacher != null;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Initialize controller and check auth status
  Future<void> initialize() async {
    if (_isInitialized) return; // Don't initialize twice

    _isLoading = true;
    // We specifically do NOT call notifyListeners here

    try {
      _currentTeacher = await _authModel.checkAuthStatus();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to initialize: ${e.toString()}';
      _currentTeacher = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;

      // Use SchedulerBinding to safely notify listeners
      _safeNotifyListeners();
    }
  }

  /// Login with passkey
  Future<bool> login(String passkey) async {
    if (passkey.trim().isEmpty) {
      _errorMessage = 'Passkey cannot be empty';
      _safeNotifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      // Change this line to use _networkService instead of _authModel
      final isConnected = await _networkService.isConnected();
      if (!isConnected) {
        _errorMessage =
            'No internet connection. Please check your network settings.';
        _isLoading = false;
        _safeNotifyListeners();
        return false;
      }

      _currentTeacher = await _authModel.verifyPasskey(passkey);
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } on ServerException catch (e) {
      // Properly extract the message from ServerException
      _errorMessage = e.message;
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    } on AuthException catch (e) {
      // Properly extract the message from AuthException
      _errorMessage = e.message;
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    } on NetworkException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    } catch (e) {
      // For other exceptions, use toString()
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      await _authModel.logout();
      _currentTeacher = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Clear any error message
  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// Safe way to notify listeners that won't cause build errors
  void _safeNotifyListeners() {
    // Check if we're in the build phase
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // If we are, use a post-frame callback to notify after the build is complete
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      // Otherwise, it's safe to notify immediately
      notifyListeners();
    }
  }
}
