// Update your attendance service to use local storage

import '../model/attendance_model.dart';
import '../core/errors/server_execption.dart';
import 'storage_services.dart';

class AttendanceService {
  final StorageService _storageService;

  AttendanceService(this._storageService);

  // Save attendance after face recognition
  Future<bool> saveAttendance(AttendanceRecord record) async {
    return await _storageService.saveAttendanceRecord(record);
  }

  // Get all dates where attendance was taken
  Future<List<DateTime>> getAttendanceDates() async {
    return await _storageService.getAttendanceDates();
  }

  // Get all class numbers for a specific date
  Future<List<int>> getClassesForDate(DateTime date) async {
    return await _storageService.getClassesForDate(date);
  }

  // Get attendance for a specific class on a specific date
  Future<AttendanceRecord?> getClassAttendance(
    DateTime date,
    int classNumber,
  ) async {
    return await _storageService.getClassAttendance(date, classNumber);
  }

  // Create attendance record from face recognition results
  Future<bool> createAttendanceFromRecognition(
    DateTime date,
    int classNumber,
    List<Map<String, dynamic>> recognitionResults,
  ) async {
    // Create attendance record
    final record = AttendanceRecord.fromRecognitionResults(
      date,
      classNumber,
      recognitionResults,
    );

    // Save to local storage
    return await saveAttendance(record);
  }
}
