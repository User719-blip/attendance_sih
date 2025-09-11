import 'package:attendance_app/core/theme/theme_data.dart';
import 'package:attendance_app/di/dependency_injection.dart' as di;
import 'package:attendance_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:attendance_app/feature/auth/presentation/bloc/auth_event.dart';
import 'package:attendance_app/feature/auth/presentation/bloc/auth_state.dart';
import 'package:attendance_app/feature/auth/presentation/page/login_page.dart';
import 'package:attendance_app/feature/auth/presentation/widget/splash_page.dart';
import 'package:attendance_app/homepage_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FaceAttendanceApp extends StatelessWidget {
  const FaceAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        // Add other BLoC providers here
      ],
      child: MaterialApp(
        title: 'Face Attendance',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const AppRouter(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const SplashPage();
        } else if (state is AuthSuccess) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
