import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import 'profile_view.dart';
import 'upload_screen.dart';
import 'med_history_screen.dart';
import 'twin_simulation_screen.dart';
import 'doctor_requests_screen.dart';
import 'reports_screen.dart';
import 'symptoms_screen.dart';
import 'about_system_screen.dart';
import 'dna_model_visualization.dart';
import 'my_doctors_screen.dart';
import 'package:genex_app/l10n/app_localizations.dart';
//done 

class ResponsiveDashboard extends ConsumerStatefulWidget {
  const ResponsiveDashboard({super.key});

  @override
  ConsumerState<ResponsiveDashboard>
      createState() =>
          _ResponsiveDashboardState();
}

class _ResponsiveDashboardState
    extends ConsumerState<
        ResponsiveDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverview(),
    const ProfileScreen(),
    const MedHistoryScreen(),
    const SymptomReportScreen(),
    const UploadScreen(),
    const TwinSimulationScreen(),
    const DoctorRequestsScreen(),
    const MyDoctorsScreen(),
    const ReportsScreen(),
    const AboutSystemScreen(),
  ];

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    bool? confirm =
        await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        backgroundColor:
            theme.colorScheme.surface,
        title: Text(
          loc.confirmLogout,
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface,
          ),
        ),
        content: Text(
          loc.logoutConfirmationMessage,
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface
                .withOpacity(0.75),
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.pop(
              context,
            ),
            child: Text(
              loc.cancel,
            ),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.red,
              foregroundColor:
                  Colors.white,
            ),
            onPressed:
                () => Navigator.pop(
              context,
              true,
            ),
            child: Text(
              loc.logout,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(
            authViewModelProvider
                .notifier,
          )
          .logout();

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(
          '/signin',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    double width =
        MediaQuery.of(context)
            .size
            .width;

    bool isDesktop =
        width > 900;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended:
                  width > 1200,
              backgroundColor:
                  theme.colorScheme
                      .surface,
              selectedIconTheme:
                  IconThemeData(
                color: theme
                    .colorScheme
                    .primary,
              ),
              unselectedIconTheme:
                  IconThemeData(
                color: theme
                    .colorScheme
                    .onSurface
                    .withOpacity(
                        0.55),
              ),
              selectedLabelTextStyle:
                  TextStyle(
                color: theme
                    .colorScheme
                    .primary,
                fontWeight:
                    FontWeight.bold,
              ),
              unselectedLabelTextStyle:
                  TextStyle(
                color: theme
                    .colorScheme
                    .onSurface
                    .withOpacity(
                        0.65),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.dashboard,
                  ),
                  label: Text(
                    loc.overview,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.person,
                  ),
                  label: Text(
                    loc.profile,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.medication,
                  ),
                  label: Text(
                    loc.history,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.sick,
                  ),
                  label: Text(
                    loc.symptoms,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.upload_file,
                  ),
                  label: Text(
                    loc.upload,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.biotech,
                  ),
                  label: Text(
                    loc.simulation,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.person_search,
                  ),
                  label: Text(
                    loc.doctorRequests,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons
                        .medical_services_outlined,
                  ),
                  label: Text(
                    loc.myDoctors,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.folder_shared,
                  ),
                  label: Text(
                    loc.reports,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.info_outline,
                  ),
                  label: Text(
                    loc.about,
                  ),
                ),
              ],
              selectedIndex:
                  _selectedIndex,
              onDestinationSelected:
                  (int index) {
                setState(
                  () => _selectedIndex =
                      index,
                );
              },
            ),

          Expanded(
            child: Container(
              color: theme
                  .scaffoldBackgroundColor,
              child: Column(
                children: [
                  _buildHeader(
                    context,
                  ),
                  Expanded(
                    child: _pages[
                        _selectedIndex
                            .clamp(
                      0,
                      _pages.length -
                          1,
                    )],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar:
          !isDesktop
              ? BottomNavigationBar(
                  currentIndex:
                      _selectedIndex > 4
                          ? 0
                          : _selectedIndex,
                  type:
                      BottomNavigationBarType
                          .fixed,
                  backgroundColor:
                      theme.colorScheme
                          .surface,
                  selectedItemColor:
                      theme.colorScheme
                          .primary,
                  unselectedItemColor:
                      theme.colorScheme
                          .onSurface
                          .withOpacity(
                              0.55),
                  onTap:
                      (index) => setState(
                    () => _selectedIndex =
                        index,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(
                        Icons.dashboard,
                      ),
                      label: loc.home,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(
                        Icons.person,
                      ),
                      label: loc.profile,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(
                        Icons.medication,
                      ),
                      label: loc.meds,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(
                        Icons.sick,
                      ),
                      label:
                          loc.symptoms,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(
                        Icons
                            .medical_services_outlined,
                      ),
                      label:
                          loc.doctors,
                    ),
                  ],
                )
              : null,
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme
                .dividerColor
                .withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            loc.geneXMedicalPortal,
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color: theme
                  .colorScheme
                  .onSurface,
            ),
          ),

          const Spacer(),

          IconButton(
            icon: const Icon(
              Icons.logout,
              color:
                  Colors.redAccent,
            ),
            tooltip: loc.logout,
            onPressed:
                _handleLogout,
          ),

          const SizedBox(width: 12),

          CircleAvatar(
            backgroundColor: theme
                .colorScheme.primary
                .withOpacity(0.12),
            child: Icon(
              Icons.person,
              color: theme
                  .colorScheme
                  .primary,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardOverview
    extends ConsumerWidget {
  const DashboardOverview({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final theme =
        Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    final medsAsync =
        ref.watch(
      medicinesProvider,
    );

    final reportsAsync =
        ref.watch(
      geneReportsProvider,
    );

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            loc.systemOverview,
            style: TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
              color: theme
                  .colorScheme
                  .onSurface,
            ),
          ),

          const SizedBox(
              height: 20),

          GridView.count(
            crossAxisCount:
                MediaQuery.of(context)
                            .size
                            .width >
                        1200
                    ? 3
                    : 2,
            shrinkWrap: true,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            physics:
                const NeverScrollableScrollPhysics(),
            children: [
              reportsAsync.when(
                data: (reports) {
                  final latestReport =
                      reports.isNotEmpty
                          ? reports.first
                          : null;

                  final String status =
                      latestReport !=
                              null
                          ? latestReport[
                              'label']
                          : loc.noData;

                  final Color
                      statusColor =
                      status.contains(
                              "High")
                          ? Colors.red
                          : Colors.green;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  const DnaModelVisualizationScreen(),
                        ),
                      );
                    },
                    borderRadius:
                        BorderRadius.circular(
                            12),
                    child:
                        _medicalWidget(
                      context,
                      loc.vitalsStatus,
                      status,
                      latestReport !=
                              null
                          ? Icons.favorite
                          : Icons.favorite_border,
                      statusColor,
                    ),
                  );
                },
                loading:
                    () => _medicalWidget(
                  context,
                  loc.vitalsStatus,
                  loc.loading,
                  Icons.favorite,
                  Colors.grey,
                ),
                error:
                    (
                      err,
                      stack,
                    ) => _medicalWidget(
                  context,
                  loc.vitalsStatus,
                  loc.error,
                  Icons.error,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _medicalWidget(
  BuildContext context,
  String title,
  String value,
  IconData icon,
  Color color,
) {
  final theme =
      Theme.of(context);

  final isDark =
      theme.brightness ==
          Brightness.dark;

  return Container(
    padding:
        const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color:
          theme.colorScheme.surface,
      borderRadius:
          BorderRadius.circular(
              12),
      border: Border.all(
        color: theme.dividerColor
            .withOpacity(0.15),
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black
                .withOpacity(0.05),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
      ],
    ),
    child: Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: 40,
        ),

        const SizedBox(
            height: 10),

        Text(
          title,
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface
                .withOpacity(0.65),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          textAlign:
              TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
            color: theme
                .colorScheme
                .onSurface,
          ),
        ),
      ],
    ),
  );
}