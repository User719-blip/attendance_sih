import 'package:flutter/material.dart';
import '../model/attendance_model.dart';
import '../services/attendance_services.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceService _attendanceService;

  List<DateTime> _attendanceDates = [];
  DateTime? _selectedDate;
  List<int> _classesForSelectedDate = [];
  AttendanceRecord? _currentAttendanceRecord;
  bool _isLoading = false;
  bool _isLoadingClassData = false;

  AttendanceController(this._attendanceService);

  // Getters
  List<DateTime> get attendanceDates => _attendanceDates;
  DateTime? get selectedDate => _selectedDate;
  List<int> get classesForSelectedDate => _classesForSelectedDate;
  bool get isLoading => _isLoading;
  bool get isLoadingClassData => _isLoadingClassData;

  // Number of present students in current record
  int get presentCount => _currentAttendanceRecord?.presentCount ?? 0;

  // Total number of students in current record
  int get totalStudents => _currentAttendanceRecord?.totalCount ?? 0;

  // Get student records from current attendance record
  List<StudentAttendance> get studentRecords =>
      _currentAttendanceRecord?.studentRecords ?? [];

  // Get attendance summary
  Map<String, Map<String, int>> get summary {
    // Example data
    return {
      'today': {'present': 24, 'total': 30},
      'week': {'present': 112, 'total': 150},
      'month': {'present': 480, 'total': 600},
    };
  }

  // Load all attendance dates
  Future<void> loadAttendanceDates() async {
    _isLoading = true;
    notifyListeners();

    try {
      _attendanceDates = await _attendanceService.getAttendanceDates();
    } catch (e) {
      print('Error loading attendance dates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a date
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Load class attendance data for a selected date and class
  Future<void> loadClassAttendance(int classNumber) async {
    if (_selectedDate == null) return;

    _isLoadingClassData = true;
    notifyListeners();

    try {
      _currentAttendanceRecord = await _attendanceService.getClassAttendance(
        _selectedDate!,
        classNumber,
      );
    } catch (e) {
      print('Error loading class attendance: $e');
    } finally {
      _isLoadingClassData = false;
      notifyListeners();
    }
  }

  // Save attendance from face recognition
  Future<bool> saveAttendanceFromRecognition(
    DateTime date,
    int classNumber,
    List<Map<String, dynamic>> recognitionResults,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _attendanceService.createAttendanceFromRecognition(
        date,
        classNumber,
        recognitionResults,
      );

      if (success) {
        // Update our lists to include this new record
        if (!_attendanceDates.contains(date)) {
          _attendanceDates.add(date);
          _attendanceDates.sort((a, b) => b.compareTo(a)); // Keep sorted
        }
      }

      return success;
    } catch (e) {
      print('Error saving attendance: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
