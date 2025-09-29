import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controller/attendance_controller.dart';
import '../widgets/connection_status_widget.dart';
import 'class_attendance_details.dart';

class AttendanceDetailPage extends StatefulWidget {
  const AttendanceDetailPage({Key? key}) : super(key: key);

  @override
  State<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  @override
  void initState() {
    super.initState();
    // Load attendance dates when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceController>(context, listen: false)
          .loadAttendanceDates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceController = Provider.of<AttendanceController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Connection status indicator
          const ConnectionStatusWidget(),
          
          // Date selection list
          Expanded(
            child: attendanceController.isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceController.attendanceDates.isEmpty
                    ? const Center(child: Text('No attendance records found'))
                    : ListView.builder(
                        itemCount: attendanceController.attendanceDates.length,
                        itemBuilder: (context, index) {
                          final date = attendanceController.attendanceDates[index];
                          return _buildDateListItem(context, date);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateListItem(BuildContext context, DateTime date) {
    final dayFormat = DateFormat('EEE'); // Mon, Tue, etc.
    final dateFormat = DateFormat('d MMM yyyy'); // 15 Jan 2023

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showClassesBottomSheet(context, date);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Date circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C86F9).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    date.day.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C86F9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Date details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayFormat.format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    dateFormat.format(date),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showClassesBottomSheet(BuildContext context, DateTime date) {
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    final dateString = "${date.day}/${date.month}/${date.year}";
    
    // Select this date in the controller
    attendanceController.selectDate(date);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Classes on $dateString',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: 5, // Classes 1-5
                itemBuilder: (context, index) {
                  final classNumber = index + 1;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4C86F9),
                      child: Text(
                        '$classNumber',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('Class $classNumber'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassAttendanceDetail(
                            date: date,
                            classNumber: classNumber,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}