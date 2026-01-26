// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/auth/signup_view.dart';
import 'views/auth/signin_view.dart';
// import 'views/home_view.dart';
import 'viewmodels/providers.dart';
// import 'views/patient/homepage_view.dart'; 
import 'views/patient/responsive_dashboard.dart';
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize providers if needed by reading them:
    ref.read(apiServiceProvider);
    ref.read(authRepositoryProvider);

    return MaterialApp(
      title: 'GeneX',



debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Clinical Medical Palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0057B7),
          primary: const Color(0xFF0057B7),
          surface: const Color(0xFFF8FAFC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0057B7),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SigninView(),
        '/signin': (ctx) => const SigninView(),
        '/signup': (ctx) => const SignupView(),
       // '/home': (ctx) => const HomeView(),
        // '/home': (ctx) => const HomeScreen(),
        // Change this line in your routes:
        '/home': (ctx) => const ResponsiveDashboard(),
      },
    );
  }
}

/*
Route _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}*/
