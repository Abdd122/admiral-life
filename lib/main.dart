
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_social/screens/auth/phone_auth_screen.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoSocial App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded buttons
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        )),
      ),
      // Set the AuthWrapper as the initial route
      home: const AuthWrapper(),
      // Define the named routes for navigation
      routes: {
        PhoneAuthScreen.routeName: (context) => const PhoneAuthScreen(),
        // Add other routes here as the app grows
      },
    );
  }
}
