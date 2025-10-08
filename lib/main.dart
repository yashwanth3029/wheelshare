// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/splash_screen.dart'; // Import the splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your URL and anon key
  await Supabase.initialize(
    url: 'https://kkgbpvsvwjayalihvyfk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtrZ2JwdnN2d2pheWFsaWh2eWZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMDU0MTUsImV4cCI6MjA3MzU4MTQxNX0.takzU2fQ0A3wDp8PD_7J5CYmhPpcsJXHuIwuUJ86NF8',
  );

  runApp(const RentWagenApp());
}

class RentWagenApp extends StatelessWidget {
  const RentWagenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WheelShare',
      theme: ThemeData(primarySwatch: Colors.blue),

      // Set the home screen to SplashScreen
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
