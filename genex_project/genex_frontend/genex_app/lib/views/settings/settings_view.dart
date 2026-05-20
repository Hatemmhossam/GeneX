// lib/views/settings/settings_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import 'package:genex_app/l10n/app_localizations.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(loc.settings),
        centerTitle: true,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= THEME =================

          Text(
            loc.appearance,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),

            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(loc.lightMode),
                  subtitle: Text(loc.lightModeSubtitle),
                  secondary: const Icon(Icons.light_mode),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).state = value!;
                  },
                ),

                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.2),
                ),

                RadioListTile<ThemeMode>(
                  title: Text(loc.darkMode),
                  subtitle: Text(loc.darkModeSubtitle),
                  secondary: const Icon(Icons.dark_mode),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).state = value!;
                  },
                ),

                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.2),
                ),

                RadioListTile<ThemeMode>(
                  title: Text(loc.systemDefault),
                  subtitle: Text(loc.systemThemeSubtitle),
                  secondary: const Icon(Icons.phone_android),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).state = value!;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ================= LANGUAGE =================

          Text(
            loc.language,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),

            child: Column(
              children: [
                RadioListTile<Locale?>(
                  title: Text(loc.systemDefault),
                  subtitle: Text(loc.followDeviceLanguage),
                  secondary: const Icon(Icons.phone_iphone),
                  value: null,
                  groupValue: locale,
                  onChanged: (value) {
                    ref.read(localeProvider.notifier).state = value;
                  },
                ),

                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.2),
                ),

                RadioListTile<Locale?>(
                  title: Text(loc.english),
                  subtitle: Text(loc.englishSubtitle),
                  secondary: const Icon(Icons.language),
                  value: const Locale('en'),
                  groupValue: locale,
                  onChanged: (value) {
                    ref.read(localeProvider.notifier).state = value;
                  },
                ),

                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.2),
                ),

                RadioListTile<Locale?>(
                  title: Text(loc.arabic),
                  subtitle: Text(loc.arabicSubtitle),
                  secondary: const Icon(Icons.translate),
                  value: const Locale('ar'),
                  groupValue: locale,
                  onChanged: (value) {
                    ref.read(localeProvider.notifier).state = value;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}