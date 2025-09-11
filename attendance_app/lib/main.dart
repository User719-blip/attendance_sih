
import 'package:attendance_app/di/dependency_injection.dart' as di;
import 'package:attendance_app/feature/auth/presentation/widget/face_attendance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Supabase
  await Supabase.initialize(
    url :'https://ylwbpjiyljtiihtqygmg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlsd2Jwaml5bGp0aWlodHF5Z21nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1NjQ2ODUsImV4cCI6MjA3MzE0MDY4NX0.TEDXKXqHb0Xce8WPU6mb_s5qTNbJcfA4fw__-KLckOM',
  );
  
  // Initialize dependency injection
  await di.init();
  
  runApp(const FaceAttendanceApp());
}