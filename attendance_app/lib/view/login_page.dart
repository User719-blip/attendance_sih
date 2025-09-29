import 'package:attendance_app/services/network_services.dart';
import 'package:attendance_app/widgets/login_background.dart';
import 'package:attendance_app/widgets/login_form.dart';
import 'package:attendance_app/widgets/network_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with blur
          const LoginBackground(),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Logo
                      const Icon(
                        Icons.face_outlined,
                        size: 80,
                        color: Color(0xFF4C86F9),
                      ),
                      const SizedBox(height: 24),

                      // Login Text
                      const Text(
                        'Teacher Login',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Login Form
                      const LoginForm(),

                      // Network Status Indicator
                      const NetworkStatusIndicator(),

                      // Consumer for network status
                      Consumer<NetworkService>(
                        builder: (context, networkService, _) {
                          return FutureBuilder<bool>(
                            future: networkService.isConnected(),
                            builder: (context, snapshot) {
                              final isOnline = snapshot.data ?? true;
                              if (!isOnline) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.wifi_off,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'No internet connection',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
