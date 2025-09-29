import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/attendance_controller.dart';
import '../model/attendance_model.dart';
import '../widgets/connection_status_widget.dart';

class AttendanceCameraPage extends StatefulWidget {
  const AttendanceCameraPage({Key? key}) : super(key: key);

  @override
  State<AttendanceCameraPage> createState() => _AttendanceCameraPageState();
}

class _AttendanceCameraPageState extends State<AttendanceCameraPage> {
  int _selectedClass = 1;
  bool _isProcessing = false;
  bool _isComplete = false;
  final List<String> _recognizedStudents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing 
              ? null 
              : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Connection status
          const ConnectionStatusWidget(),
          
          // Class selection
          if (!_isProcessing && !_isComplete)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Class:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedClass,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: List.generate(5, (index) {
                      final classNum = index + 1;
                      return DropdownMenuItem(
                        value: classNum,
                        child: Text('Class $classNum'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedClass = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          
          // Camera preview placeholder
          if (!_isProcessing && !_isComplete)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Camera preview would appear here',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Integrate with camera plugin',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Processing indicator
          if (_isProcessing)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text('Processing face recognition...'),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we analyze the faces',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          
          // Completion view
          if (_isComplete)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Attendance Complete!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${_recognizedStudents.length} students recognized',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/attendance/detail');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('View Attendance Records'),
                  ),
                ],
              ),
            ),
            
          // Action buttons
          if (!_isProcessing && !_isComplete)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _captureAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C86F9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('CAPTURE ATTENDANCE'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _captureAttendance() async {
    setState(() {
      _isProcessing = true;
    });
    
    // Simulate face recognition process
    await Future.delayed(const Duration(seconds: 3));
    
    // Mock recognition results
    final mockRecognitionResults = List.generate(
      25,
      (index) => {
        'student_id': 'S${100 + index}',
        'student_name': 'Student ${index + 1}',
        'is_recognized': index % 5 != 0, // 80% attendance
      },
    );
    
    // Extract recognized students
    final List<String> recognized = [];
    for (var result in mockRecognitionResults) {
      if (result['is_recognized'] == true) {
        recognized.add(result['student_name'] as String);
      }
    }
    
    // Save the attendance
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);
    final success = await attendanceController.saveAttendanceFromRecognition(
      DateTime.now(),
      _selectedClass,
      mockRecognitionResults,
    );
    
    if (success) {
      setState(() {
        _isProcessing = false;
        _isComplete = true;
        _recognizedStudents.addAll(recognized);
      });
    } else {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save attendance. Please try again.'),
          ),
        );
      }
    }
  }
}