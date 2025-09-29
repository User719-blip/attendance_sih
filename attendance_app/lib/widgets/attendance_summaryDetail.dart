import 'package:flutter/material.dart' show Border, BorderRadius, BoxDecoration, BoxShape, BuildContext, Card, Center, Color, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, MainAxisAlignment, MainAxisSize, Padding, RoundedRectangleBorder, Row, SizedBox, StatelessWidget, Text, TextStyle, Widget;
import 'package:intl/intl.dart';

class AttendanceSummaryDetailCard extends StatelessWidget {
  final int present;
  final int total;
  final DateTime date;
  final int classNumber;
  
  const AttendanceSummaryDetailCard({
    super.key,
    required this.present,
    required this.total,
    required this.date,
    required this.classNumber,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final attendancePercentage = total > 0 ? (present / total * 100).round() : 0;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Class $classNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  dateFormat.format(date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttendanceCircle(present, total, attendancePercentage),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow('Present', present, Colors.green),
                    const SizedBox(height: 8),
                    _buildStatusRow('Absent', total - present, Colors.red),
                    const SizedBox(height: 8),
                    _buildStatusRow('Total', total, Colors.blue),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttendanceCircle(int present, int total, int percentage) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: _getColorForPercentage(percentage),
          width: 8,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getColorForPercentage(percentage),
              ),
            ),
            const Text(
              'Attendance',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Color _getColorForPercentage(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}