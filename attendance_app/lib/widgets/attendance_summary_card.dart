import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/attendance_controller.dart';

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceController = Provider.of<AttendanceController>(context);
    final summary = attendanceController.summary;

    // Get values from the controller
    final todayPresent = summary['today']?['present'] ?? 0;
    final todayTotal = summary['today']?['total'] ?? 0;
    final weekPresent = summary['week']?['present'] ?? 0;
    final weekTotal = summary['week']?['total'] ?? 0;
    final monthPresent = summary['month']?['present'] ?? 0;
    final monthTotal = summary['month']?['total'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Today',
                  '$todayPresent/$todayTotal',
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'This Week',
                  '$weekPresent/$weekTotal',
                  Colors.green,
                ),
                _buildSummaryItem(
                  'This Month',
                  '$monthPresent/$monthTotal',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
