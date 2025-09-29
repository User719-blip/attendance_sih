import 'package:attendance_app/services/attendance_services.dart';
import 'package:attendance_app/view/attendance_detail.dart';
import 'package:attendance_app/view/camra_page_stub.dart';
import 'package:attendance_app/view/class_attendance_details.dart';
import 'package:attendance_app/widgets/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'controller/auth_controller.dart';
import 'controller/attendance_controller.dart';
import 'core/networks/network_connection.dart';
import 'model/auth_model.dart';
import 'services/auth_services.dart';
import 'services/network_services.dart';
import 'services/storage_services.dart';
import 'view/home_page.dart';
import 'view/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e");
    // Fallback values for development
    dotenv.env['SUPABASE_URL'] = 'https://ylwbpjiyljtiihtqygmg.supabase.co';
    dotenv.env['SUPABASE_ANON_KEY'] = 'your-anon-key-here';
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: (dotenv.env['SUPABASE_URL'] ?? '').trim(),
    anonKey: (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim(),
  );

  // Add more debug output
  final supabaseClient = Supabase.instance.client;
  print(
    'Auth header present: ${supabaseClient.auth.headers.containsKey('Authorization')}',
  );

  // Create NetworkInfo implementation
  final networkInfo = NetworkInfoImpl(connectivity: Connectivity());

  // Initialize services
  final authService = AuthService(supabaseClient);
  final storageService = StorageService();
  final networkService = NetworkService(networkInfo);
  final attendanceService = AttendanceService(storageService);

  // Initialize model
  final authModel = AuthModel(
    authService: authService,
    storageService: storageService,
    networkService: networkService,
  );

  runApp(
    MyApp(
      authModel: authModel,
      networkService: networkService,
      attendanceService: attendanceService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthModel authModel;
  final NetworkService networkService;
  final AttendanceService attendanceService;

  const MyApp({
    super.key,
    required this.authModel,
    required this.networkService,
    required this.attendanceService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(authModel, networkService),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceController(attendanceService),
        ),
        Provider<NetworkService>.value(value: networkService),
      ],
      child: MaterialApp(
        title: 'Face Attendance',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const AuthStateWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/attendance/detail': (context) =>
              const AttendanceDetailPage(), // Changed this line
          '/attendance/camera': (context) => const AttendanceCameraPage(),
        },
      ),
    );
  }
}
