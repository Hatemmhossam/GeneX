// lib/views/settings/settings_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/providers.dart';
import 'package:genex_app/l10n/app_localizations.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.settings),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _SettingsHero(theme: theme, title: loc.settings),
          const SizedBox(height: 28),

          _SectionTitle(
            icon: Icons.palette_rounded,
            title: loc.appearance,
          ),

          const SizedBox(height: 14),

          _SettingsCard(
            children: [
              _OptionTile<ThemeMode>(
                title: loc.lightMode,
                subtitle: loc.lightModeSubtitle,
                icon: Icons.light_mode_rounded,
                value: ThemeMode.light,
                groupValue: themeMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).state = value!;
                },
              ),
              _Divider(),
              _OptionTile<ThemeMode>(
                title: loc.darkMode,
                subtitle: loc.darkModeSubtitle,
                icon: Icons.dark_mode_rounded,
                value: ThemeMode.dark,
                groupValue: themeMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).state = value!;
                },
              ),
              _Divider(),
              _OptionTile<ThemeMode>(
                title: loc.systemDefault,
                subtitle: loc.systemThemeSubtitle,
                icon: Icons.phone_android_rounded,
                value: ThemeMode.system,
                groupValue: themeMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).state = value!;
                },
              ),
            ],
          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08),

          const SizedBox(height: 32),

          _SectionTitle(
            icon: Icons.language_rounded,
            title: loc.language,
          ),

          const SizedBox(height: 14),

          _SettingsCard(
            children: [
              _OptionTile<Locale?>(
                title: loc.systemDefault,
                subtitle: loc.followDeviceLanguage,
                icon: Icons.phone_iphone_rounded,
                value: null,
                groupValue: locale,
                onChanged: (value) {
                  ref.read(localeProvider.notifier).state = value;
                },
              ),
              _Divider(),
              _OptionTile<Locale?>(
                title: loc.english,
                subtitle: loc.englishSubtitle,
                icon: Icons.translate_rounded,
                value: const Locale('en'),
                groupValue: locale,
                onChanged: (value) {
                  ref.read(localeProvider.notifier).state = value;
                },
              ),
              _Divider(),
              _OptionTile<Locale?>(
                title: loc.arabic,
                subtitle: loc.arabicSubtitle,
                icon: Icons.g_translate_rounded,
                value: const Locale('ar'),
                groupValue: locale,
                onChanged: (value) {
                  ref.read(localeProvider.notifier).state = value;
                },
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),
        ],
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  final ThemeData theme;
  final String title;

  const _SettingsHero({
    required this.theme,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08);
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 22,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.22 : 0.06,
            ),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  bool get isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      secondary: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.14)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.35)
                : theme.dividerColor.withOpacity(0.16),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.iconTheme.color?.withOpacity(0.65),
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.68),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Divider(
      height: 1,
      indent: 72,
      endIndent: 18,
      color: theme.dividerColor.withOpacity(0.14),
    );
  }
}