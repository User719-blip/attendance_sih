import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import '../view/home_page.dart';
import '../view/login_page.dart';

class AuthStateWrapper extends StatefulWidget {
  const AuthStateWrapper({super.key});

  @override
  State<AuthStateWrapper> createState() => _AuthStateWrapperState();
}

class _AuthStateWrapperState extends State<AuthStateWrapper> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // Delay initialization to avoid build phase issues
    _initFuture = Future.microtask(() {
      if (!mounted) return null;
      return Provider.of<AuthController>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Consumer<AuthController>(
          builder: (_, authController, __) {
            // Show loading state during initialization
            if (authController.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // After initialization, show appropriate screen
            return authController.isAuthenticated
                ? const HomePage()
                : const LoginPage();
          },
        );
      },
    );
  }
}
