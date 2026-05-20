// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:genex_app/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'views/auth/signup_view.dart';
import 'views/auth/signin_view.dart';
import 'viewmodels/providers.dart';
import 'views/patient/responsive_dashboard.dart';
import 'views/auth/doctor_dashboard.dart';
import 'views/doctor/user_search_view.dart';
import 'views/settings/settings_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(apiServiceProvider);
    ref.read(authRepositoryProvider);

    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'GeneX',
      debugShowCheckedModeBanner: false,

      locale: locale,

      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      initialRoute: '/',

      routes: {
        '/': (ctx) => const SigninView(),
        '/signin': (ctx) => const SigninView(),
        '/signup': (ctx) => const SignupView(),
        '/home': (ctx) => const ResponsiveDashboard(),
        '/doctor': (ctx) => const DoctorDashboard(),
        '/user-search': (ctx) => const UserSearchView(),
        '/settings': (ctx) => const SettingsView(),
      },
    );
  }
}