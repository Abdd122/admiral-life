
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart'; // Assuming a HomeScreen exists
import '../screens/login_screen.dart';

// This widget is the entry point of the app after initialization.
// It listens to the authentication state and shows the appropriate screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // While waiting for the auth state, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user is logged in, show the home screen
        if (snapshot.hasData && snapshot.data != null) {
          // We can pass the user object to the home screen if needed
          return HomeScreen(user: snapshot.data!);
        }

        // If the user is not logged in, show the login screen
        return const LoginScreen();
      },
    );
  }
}

