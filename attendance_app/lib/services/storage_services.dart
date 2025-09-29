import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/teacher_model.dart';
import '../model/attendance_model.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _teacherIdKey = 'teacher_id';
  static const String _teacherNameKey = 'teacher_name';
  static const String _passkeyHashKey = 'passkey_hash';
  static const String _setupCompleteKey = 'setup_complete';

  /// Cache authentication data
  Future<void> cacheAuthData(Teacher teacher, String passkey) async {
    final prefs = await SharedPreferences.getInstance();

    // Hash the passkey
    final hashedPasskey = _hashPasskey(passkey);

    // Store teacher and auth data
    await prefs.setString(_tokenKey, teacher.token);
    await prefs.setString(_teacherIdKey, teacher.id);
    await prefs.setString(_teacherNameKey, teacher.name);
    await prefs.setString(_passkeyHashKey, hashedPasskey);
    await prefs.setBool(_setupCompleteKey, true);
  }

  /// Check if setup is complete
  Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompleteKey) ?? false;
  }

  /// Validate passkey against stored hash
  Future<bool> validatePasskey(String passkey) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passkeyHashKey);

    if (storedHash == null) {
      return false;
    }

    final inputHash = _hashPasskey(passkey);
    return storedHash == inputHash;
  }

  /// Get cached teacher data
  Future<Teacher?> getCachedTeacher() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);
    final id = prefs.getString(_teacherIdKey);
    final name = prefs.getString(_teacherNameKey);

    if (token == null || id == null) {
      return null;
    }

    return Teacher(id: id, name: name ?? 'Teacher', token: token);
  }

  /// Clear auth data (logout)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    // Keep hash for easier re-login
    await prefs.remove(_passkeyHashKey);
    await prefs.remove(_setupCompleteKey);
  }

  /// Hash passkey for secure storage
  String _hashPasskey(String passkey) {
    final bytes = utf8.encode(passkey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Save attendance record locally
  Future<bool> saveAttendanceRecord(AttendanceRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a unique key for this attendance record
      final recordKey =
          'attendance_${record.date.toIso8601String().split('T')[0]}_${record.classNumber}';

      // Convert to JSON and store
      final recordJson = jsonEncode(record.toJson());
      await prefs.setString(recordKey, recordJson);

      // Also store the date in a list of all attendance dates for easy retrieval
      final datesList = prefs.getStringList('attendance_dates') ?? [];
      final dateString = record.date.toIso8601String().split('T')[0];

      if (!datesList.contains(dateString)) {
        datesList.add(dateString);
        await prefs.setStringList('attendance_dates', datesList);
      }

      return true;
    } catch (e) {
      print('Error saving attendance record: $e');
      return false;
    }
  }

  /// Get all attendance dates
  Future<List<DateTime>> getAttendanceDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final datesList = prefs.getStringList('attendance_dates') ?? [];

      // Sort dates in descending order (newest first)
      datesList.sort((a, b) => b.compareTo(a));

      return datesList.map((dateStr) => DateTime.parse(dateStr)).toList();
    } catch (e) {
      print('Error getting attendance dates: $e');
      return [];
    }
  }

  /// Get attendance for a specific class on a specific date
  Future<AttendanceRecord?> getClassAttendance(
    DateTime date,
    int classNumber,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordKey =
          'attendance_${date.toIso8601String().split('T')[0]}_$classNumber';

      final recordJson = prefs.getString(recordKey);
      if (recordJson == null) {
        return null;
      }

      final recordMap = jsonDecode(recordJson);
      return AttendanceRecord.fromJson(recordMap);
    } catch (e) {
      print('Error getting attendance record: $e');
      return null;
    }
  }

  /// Get all class numbers for a specific date
  Future<List<int>> getClassesForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = date.toIso8601String().split('T')[0];

      // Get all keys and filter for this date
      final keys = prefs.getKeys();
      final classKeys = keys
          .where((key) => key.startsWith('attendance_$dateString'))
          .toList();

      // Extract class numbers from keys
      return classKeys.map((key) {
        final parts = key.split('_');
        return int.parse(parts.last);
      }).toList();
    } catch (e) {
      print('Error getting classes for date: $e');
      return [];
    }
  }
}
