// Create or update your attendance model class

import 'dart:convert';

class AttendanceRecord {
  final String id;
  final DateTime date;
  final int classNumber;
  final List<StudentAttendance> studentRecords;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.classNumber,
    required this.studentRecords,
  });

  int get presentCount => studentRecords.where((s) => s.isPresent).length;
  int get totalCount => studentRecords.length;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      date: DateTime.parse(json['date']),
      classNumber: json['class_number'],
      studentRecords: (json['student_records'] as List)
          .map((s) => StudentAttendance.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'class_number': classNumber,
      'student_records': studentRecords.map((s) => s.toJson()).toList(),
    };
  }

  // Factory method to create from face recognition results
  factory AttendanceRecord.fromRecognitionResults(
    DateTime date,
    int classNumber,
    List<Map<String, dynamic>> recognitionResults,
  ) {
    final studentRecords = recognitionResults.map((result) {
      return StudentAttendance(
        studentId: result['student_id'],
        studentName: result['student_name'],
        isPresent: result['is_recognized'] ?? false,
      );
    }).toList();

    return AttendanceRecord(
      id: 'local_${date.millisecondsSinceEpoch}_$classNumber',
      date: date,
      classNumber: classNumber,
      studentRecords: studentRecords,
    );
  }
}

class StudentAttendance {
  final String studentId;
  final String studentName;
  final bool isPresent;

  StudentAttendance({
    required this.studentId,
    required this.studentName,
    required this.isPresent,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    return StudentAttendance(
      studentId: json['student_id'],
      studentName: json['student_name'],
      isPresent: json['is_present'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'is_present': isPresent,
    };
  }
}
