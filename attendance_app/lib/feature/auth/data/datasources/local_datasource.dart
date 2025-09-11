import 'dart:convert';
import 'package:attendance_app/core/errors/server_execption.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';


abstract class AuthLocalDataSource {
  /// Stores auth token and passkey hash locally
  Future<void> cacheAuthData(String token, String passkey);
  
  /// Gets cached auth token
  Future<String> getCachedToken();
  
  /// Gets cached teacher ID
  Future<String> getCachedTeacherId();
  
  /// Gets cached teacher name
  Future<String> getCachedTeacherName();
  
  /// Validates passkey against stored hash
  Future<bool> validatePasskey(String passkey);
  
  /// Checks if user has completed initial setup
  Future<bool> isInitialSetupComplete();
  
  /// Checks if token exists and is not expired
  Future<bool> hasValidToken();
  
  /// Clears all auth data (logout)
  Future<void> clearAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  AuthLocalDataSourceImpl({required this.sharedPreferences});
  
  static const String _cachedTokenKey = 'CACHED_TOKEN';
  static const String _cachedTeacherIdKey = 'CACHED_TEACHER_ID';
  static const String _cachedTeacherNameKey = 'CACHED_TEACHER_NAME';
  static const String _passKeyHashKey = 'PASSKEY_HASH';
  static const String _initialSetupKey = 'INITIAL_SETUP_COMPLETE';
  static const String _tokenExpiryKey = 'TOKEN_EXPIRY';
  
  @override
  Future<void> cacheAuthData(String token, String passkey, 
      {String? teacherId, String? teacherName}) async {
    final String hashedPasskey = _hashPasskey(passkey);
    
    // Set token expiry to 30 days from now
    final tokenExpiry = DateTime.now().add(const Duration(days: 30));
    
    final tokenSaved = await sharedPreferences.setString(_cachedTokenKey, token);
    final hashSaved = await sharedPreferences.setString(_passKeyHashKey, hashedPasskey);
    final setupSaved = await sharedPreferences.setBool(_initialSetupKey, true);
    final expirySaved = await sharedPreferences.setString(
      _tokenExpiryKey, tokenExpiry.toIso8601String());
    
    // Save teacher data if provided
    bool idSaved = true, nameSaved = true;
    if (teacherId != null) {
      idSaved = await sharedPreferences.setString(_cachedTeacherIdKey, teacherId);
    }
    if (teacherName != null) {
      nameSaved = await sharedPreferences.setString(_cachedTeacherNameKey, teacherName);
    }
    
    if (!tokenSaved || !hashSaved || !setupSaved || !expirySaved || !idSaved || !nameSaved) {
      throw CacheException(message: 'Failed to save authentication data');
    }
  }
  
  @override
  Future<String> getCachedToken() async {
    final token = sharedPreferences.getString(_cachedTokenKey);
    if (token == null) {
      throw CacheException(message: 'No cached token found');
    }
    return token;
  }
  
  @override
  Future<String> getCachedTeacherId() async {
    final id = sharedPreferences.getString(_cachedTeacherIdKey);
    if (id == null) {
      throw CacheException(message: 'No cached teacher ID found');
    }
    return id;
  }
  
  @override
  Future<String> getCachedTeacherName() async {
    final name = sharedPreferences.getString(_cachedTeacherNameKey);
    if (name == null) {
      return 'Teacher'; // Default name if not found
    }
    return name;
  }
  
  @override
  Future<bool> validatePasskey(String passkey) async {
    final storedHash = sharedPreferences.getString(_passKeyHashKey);
    if (storedHash == null) {
      throw CacheException(message: 'No passkey hash found');
    }
    
    final inputHash = _hashPasskey(passkey);
    return storedHash == inputHash;
  }
  
  @override
  Future<bool> isInitialSetupComplete() async {
    return sharedPreferences.getBool(_initialSetupKey) ?? false;
  }
  
  @override
  Future<bool> hasValidToken() async {
    final token = sharedPreferences.getString(_cachedTokenKey);
    final expiryString = sharedPreferences.getString(_tokenExpiryKey);
    
    if (token == null || expiryString == null) {
      return false;
    }
    
    try {
      final expiry = DateTime.parse(expiryString);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return false;
    }
  }
  
  @override
  Future<void> clearAuthData() async {
    await sharedPreferences.remove(_cachedTokenKey);
    await sharedPreferences.remove(_tokenExpiryKey);
    // Optionally keep the passkey hash for faster re-login
    // await sharedPreferences.remove(_passKeyHashKey);
    // await sharedPreferences.remove(_initialSetupKey);
  }
  
  String _hashPasskey(String passkey) {
    final bytes = utf8.encode(passkey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}