import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genex_app/l10n/app_localizations.dart';
import 'patient_medical_history.dart';
import '../shared/chat_screen.dart';
//done
class PatientProfile {
  final int? id;
  final int? conversationId;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final double? weight;
  final double? height;

  PatientProfile({
    this.id,
    this.conversationId,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.weight,
    this.height,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'],
        conversationId: json['conversation_id'] ??
          json['conversationId'] ??
          json['conversation']?['id'],
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      age: json['age'],
      gender: json['gender'],
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
    );
  }
}

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState
    extends State<DoctorDashboardScreen> {
  List<PatientProfile> patients = [];
  List<PatientProfile> filteredPatients = [];
  bool _isLoading = true;

  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMyPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPatients);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyPatients() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url =
        Uri.parse('http://127.0.0.1:8000/api/doctor/my-patients/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final loadedPatients =
            data.map((json) => PatientProfile.fromJson(json)).toList();

        setState(() {
          patients = loadedPatients;
          filteredPatients = loadedPatients;
          _isLoading = false;
        });
      } else {
        debugPrint("Error: ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterPatients() {
    final query =
        _searchController.text.trim().toLowerCase();

    setState(() {
      filteredPatients = patients.where((patient) {
        return patient.name
                .toLowerCase()
                .contains(query) ||
            patient.email
                .toLowerCase()
                .contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide =
        MediaQuery.of(context).size.width > 900;

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            theme.appBarTheme.backgroundColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor,
        centerTitle: true,
        title: Text(
          loc.myPatients,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: loc.refresh,
            onPressed: _fetchMyPatients,
            icon: Icon(
              Icons.refresh_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyPatients,
        child: _isLoading
            ? const _LoadingView()
            : patients.isEmpty
                ? const _EmptyPatientsView()
                : Column(
                    children: [
                      _buildTopSection(
                        isWide,
                        loc,
                      ),
                      Expanded(
                        child:
                            filteredPatients.isEmpty
                                ? const _NoSearchResultsView()
                                : Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      20,
                                      8,
                                      20,
                                      20,
                                    ),
                                    child:
                                        GridView.builder(
                                      itemCount:
                                          filteredPatients
                                              .length,
                                      gridDelegate:
                                          SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent:
                                            isWide
                                                ? 420
                                                : 500,
                                        childAspectRatio:
                                            isWide
                                                ? 1.15
                                                : 1.05,
                                        crossAxisSpacing:
                                            18,
                                        mainAxisSpacing:
                                            18,
                                      ),
                                      itemBuilder:
                                          (
                                            context,
                                            index,
                                          ) {
                                        final p =
                                            filteredPatients[
                                                index];

                                        return _PatientCard(
                                          patient: p,
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTopSection(
    bool isWide,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
  colors: [
    Color(0xFF0F172A),
    Color(0xFF1E3A8A),
    Color(0xFF2563EB),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color:
                  theme.colorScheme.primary.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  child:
                      _buildHeaderText(loc),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child:
                      _buildSearchBar(loc),
                ),
              ],
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeaderText(loc),
                const SizedBox(height: 16),
                _buildSearchBar(loc),
              ],
            ),
    );
  }

  Widget _buildHeaderText(
    AppLocalizations loc,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          loc.doctorDashboard,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.doctorDashboardSubtitle,
          style: TextStyle(
            color:
                Colors.white.withOpacity(0.92),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.14),
            borderRadius:
                BorderRadius.circular(999),
          ),
          child: Text(
            "${patients.length} ${loc.patients}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color:
            theme.inputDecorationTheme.fillColor,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        textDirection:
            Directionality.of(context),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: loc.searchByPatient,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface
                .withOpacity(0.55),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color:
                theme.colorScheme.primary,
          ),
          suffixIcon:
              _searchController
                      .text
                      .isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController
                            .clear();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme
                            .colorScheme
                            .primary,
                      ),
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide:
                BorderSide.none,
          ),
          filled: true,
          fillColor: theme
              .inputDecorationTheme
              .fillColor,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientProfile patient;

  const _PatientCard({
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final isDark =
        theme.brightness == Brightness.dark;

    final String firstLetter =
        patient.name.isNotEmpty
            ? patient.name[0].toUpperCase()
            : '?';

    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
        border: Border.all(
          color: theme.dividerColor
              .withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFF06B6D4),
                        Color(0xFF2563EB),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        patient.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                          color: theme
                              .colorScheme
                              .onSurface,
                        ),
                      ),
                      const SizedBox(
                          height: 4),
                      Text(
                        patient.email,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurface
                              .withOpacity(
                                  0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(
                  icon:
                      Icons.cake_outlined,
                  label: loc.age,
                  value:
                      patient.age
                          ?.toString() ??
                      '-',
                ),
                _InfoChip(
                  icon:
                      Icons.wc_outlined,
                  label: loc.gender,
                  value:
                      patient.gender ??
                      '-',
                ),
                _InfoChip(
                  icon: Icons
                      .monitor_weight_outlined,
                  label: loc.weight,
                  value:
                      patient.weight !=
                              null
                          ? "${patient.weight!.toStringAsFixed(1)} kg"
                          : '-',
                ),
                _InfoChip(
                  icon:
                      Icons.height_outlined,
                  label: loc.height,
                  value:
                      patient.height !=
                              null
                          ? "${patient.height!.toStringAsFixed(1)} cm"
                          : '-',
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  if (patient.id !=
                      null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                PatientMedicalHistoryScreen(
                          patientId:
                              patient.id!,
                          patientName:
                              patient.name,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.patientIdMissing,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons
                      .folder_open_rounded,
                ),
                label: Text(
                  loc.viewMedicalRecords,
                ),
                style:
                    ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme
                      .colorScheme
                      .primary,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                                16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
            theme.scaffoldBackgroundColor,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor
              .withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Roboto',
                color:
                    theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurface,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Center(
          child:
              CircularProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            loc.loadingPatients,
            style: TextStyle(
              color: theme
                  .colorScheme.onSurface
                  .withOpacity(0.65),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyPatientsView
    extends StatelessWidget {
  const _EmptyPatientsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(
          Icons.groups_rounded,
          size: 90,
          color: theme
              .colorScheme.onSurface
              .withOpacity(0.25),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            loc.noAcceptedPatients,
            style: theme
                .textTheme.titleLarge
                ?.copyWith(
              fontWeight:
                  FontWeight.bold,
              color: theme
                  .colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            loc.patientsWillAppearHere,
            textAlign: TextAlign.center,
            style: theme
                .textTheme.bodyMedium
                ?.copyWith(
              color: theme
                  .colorScheme.onSurface
                  .withOpacity(0.65),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoSearchResultsView
    extends StatelessWidget {
  const _NoSearchResultsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Text(
        loc.noPatientsMatchSearch,
        style: theme.textTheme.bodyMedium
            ?.copyWith(
          fontSize: 16,
          color: theme
              .colorScheme.onSurface
              .withOpacity(0.65),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}