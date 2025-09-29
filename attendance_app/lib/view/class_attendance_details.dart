// ignore_for_file: depend_on_referenced_packages

import 'package:attendance_app/widgets/attendance_summaryDetail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/attendance_controller.dart';
import '../widgets/attendance_list_widget.dart';

class ClassAttendanceDetail extends StatefulWidget {
  final DateTime date;
  final int classNumber;

  const ClassAttendanceDetail({
    super.key,
    required this.date,
    required this.classNumber,
  });

  @override
  State<ClassAttendanceDetail> createState() => _ClassAttendanceDetailState();
}

class _ClassAttendanceDetailState extends State<ClassAttendanceDetail> {
  @override
  void initState() {
    super.initState();
    // Load class attendance data when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceController>(
        context,
        listen: false,
      ).loadClassAttendance(widget.classNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceController = Provider.of<AttendanceController>(context);
    final dateString =
        "${widget.date.day}/${widget.date.month}/${widget.date.year}";

    return Scaffold(
      appBar: AppBar(title: Text('Class ${widget.classNumber} - $dateString')),
      body: attendanceController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Use the new detail card
                AttendanceSummaryDetailCard(
                  present: attendanceController.presentCount,
                  total: attendanceController.totalStudents,
                  date: widget.date,
                  classNumber: widget.classNumber,
                ),

                // List header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'No.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Student Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Student Attendance List
                Expanded(
                  child: StudentAttendanceList(
                    attendanceRecords: attendanceController.studentRecords,
                  ),
                ),
              ],
            ),
    );
  }
}
