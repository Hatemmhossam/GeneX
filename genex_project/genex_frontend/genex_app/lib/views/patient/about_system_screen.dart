import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:genex_app/l10n/app_localizations.dart';

//done
class AboutSystemScreen extends StatelessWidget {
  const AboutSystemScreen({super.key});

  Widget _sectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = color ?? theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.15),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cardColor.withOpacity(0.12),
            child: Icon(icon, color: cardColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimerCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.12) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.red.withOpacity(0.35) : Colors.red.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isDark ? Colors.red.shade300 : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.importantMedicalDisclaimer,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.red.shade300 : Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loc.medicalDisclaimerContent,
                  style: TextStyle(
                    color: isDark ? Colors.red.shade200 : Colors.red,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedItem(Widget child, int index) {
    return child.animate().slideY(
          begin: 0.06,
          delay: (index * 70).ms,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.aboutTheSystem,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animatedItem(
              _sectionCard(
                context: context,
                icon: Icons.psychology,
                title: loc.purpose,
                content: loc.purposeContent,
                color: Colors.teal,
              ),
              0,
            ),
            _animatedItem(
              _sectionCard(
                context: context,
                icon: Icons.star,
                title: loc.mainFeatures,
                content: loc.mainFeaturesContent,
                color: Colors.blue,
              ),
              1,
            ),
            _animatedItem(
              _sectionCard(
                context: context,
                icon: Icons.settings,
                title: loc.howSystemWorks,
                content: loc.howSystemWorksContent,
                color: Colors.deepPurple,
              ),
              2,
            ),
            _animatedItem(
              _sectionCard(
                context: context,
                icon: Icons.info_outline,
                title: loc.limitations,
                content: loc.limitationsContent,
                color: Colors.orange,
              ),
              3,
            ),
            _animatedItem(
              _disclaimerCard(context),
              4,
            ),
          ],
        ),
      ),
    );
  }
}