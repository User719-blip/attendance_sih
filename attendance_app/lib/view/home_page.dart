import 'package:attendance_app/widgets/connection_status_widget.dart';
import 'package:attendance_app/widgets/home_content.dart';
import 'package:attendance_app/widgets/logout_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        actions: const [LogoutButton()],
      ),
      body: authController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Stack(
              children: [
                // Main content
                HomeContent(),

                // Attendance buttons positioned at bottom RIGHT
                Positioned(
                  right: 16, // Changed from left to right
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end, // Changed to end alignment
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Take Attendance Button
                      AttendanceActionButton(
                        label: 'Take Attendance',
                        icon: Icons.camera_alt,
                        route: '/attendance/camera',
                      ),
                      SizedBox(height: 12),
                      // View Attendance Button
                      AttendanceActionButton(
                        label: 'View Attendance',
                        icon: Icons.list_alt,
                        route: '/attendance/detail',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// Updated button component with square shape and darker blue
class AttendanceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const AttendanceActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 24), // Larger icon
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16, // Larger text
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: () => Navigator.pushNamed(context, route),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A4799), // Darker blue color
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24, // Larger horizontal padding
          vertical: 16, // Larger vertical padding
        ),
        minimumSize: const Size(180, 54), // Set minimum size
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12,
          ), // Less rounded corners for more square look
        ),
        elevation: 3, // Add some elevation
      ),
    );
  }
}
