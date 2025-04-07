import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travelcompanionfinder/firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // Import Home Screen
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel Companion',
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: AppTheme.secondaryColor,
        textTheme: TextTheme(
          displayLarge: AppTheme.headingStyle,
          titleMedium: AppTheme.subHeadingStyle,
          bodyLarge: AppTheme.bodyTextStyle,
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.black45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: AuthChecker(), // Start with AuthChecker
    );
  }
}

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(), // Listen for auth changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              body: Center(child: CircularProgressIndicator())); // Show loading
        } else if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(); // User is logged in
        } else {
          return LoginScreen(); // No user logged in
        }
      },
    );
  }
}
