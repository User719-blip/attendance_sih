import 'package:flutter/material.dart';
import '../model/attendance_model.dart';

class StudentAttendanceList extends StatelessWidget {
  final List<StudentAttendance> attendanceRecords;
  
  const StudentAttendanceList({
    Key? key,
    required this.attendanceRecords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: attendanceRecords.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = attendanceRecords[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Text('${index + 1}'),
          ),
          title: Text(
            record.studentName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: record.isPresent ? Colors.green.shade100 : Colors.red.shade100,
            ),
            child: Center(
              child: Text(
                record.isPresent ? 'P' : 'A',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: record.isPresent ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}