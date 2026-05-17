import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'patient_medical_history.dart';

class PatientProfile {
  final int? id;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final double? weight;
  final double? height;

  PatientProfile({
    this.id,
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
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  List<PatientProfile> patients = [];
  List<PatientProfile> filteredPatients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

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
    final url = Uri.parse('http://127.0.0.1:8000/api/doctor/my-patients/');

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
        final loadedPatients = data
            .map((json) => PatientProfile.fromJson(json))
            .toList();

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
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      filteredPatients = patients.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
            patient.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text(
          "My Patients",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _fetchMyPatients,
            icon: const Icon(Icons.refresh_rounded),
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
                  _buildTopSection(isWide),
                  Expanded(
                    child: filteredPatients.isEmpty
                        ? const _NoSearchResultsView()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            child: GridView.builder(
                              itemCount: filteredPatients.length,
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: isWide ? 420 : 500,
                                    childAspectRatio: isWide ? 1.45 : 1.25,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                  ),
                              itemBuilder: (context, index) {
                                final p = filteredPatients[index];
                                return _PatientCard(patient: p);
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopSection(bool isWide) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _buildHeaderText()),
                const SizedBox(width: 20),
                Expanded(child: _buildSearchBar()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderText(),
                const SizedBox(height: 16),
                _buildSearchBar(),
              ],
            ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Doctor Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Manage your accepted patients and open their medical records quickly.",
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "${patients.length} patient${patients.length == 1 ? '' : 's'}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by patient name or email",
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientProfile patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final String firstLetter = patient.name.isNotEmpty
        ? patient.name[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
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
                  icon: Icons.cake_outlined,
                  label: "Age",
                  value: patient.age?.toString() ?? '-',
                ),
                _InfoChip(
                  icon: Icons.wc_outlined,
                  label: "Gender",
                  value: patient.gender ?? '-',
                ),
                _InfoChip(
                  icon: Icons.monitor_weight_outlined,
                  label: "Weight",
                  value: patient.weight != null
                      ? "${patient.weight!.toStringAsFixed(1)} kg"
                      : '-',
                ),
                _InfoChip(
                  icon: Icons.height_outlined,
                  label: "Height",
                  value: patient.height != null
                      ? "${patient.height!.toStringAsFixed(1)} cm"
                      : '-',
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (patient.id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientMedicalHistoryScreen(
                          patientId: patient.id!,
                          patientName: patient.name,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error: Patient ID is missing"),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text("View Medical Records"),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Roboto'),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 16),
        Center(
          child: Text(
            "Loading patients...",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

class _EmptyPatientsView extends StatelessWidget {
  const _EmptyPatientsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.groups_rounded, size: 90, color: Colors.grey.shade300),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            "No accepted patients yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "Once patients are assigned and accepted,\nyou’ll see them here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _NoSearchResultsView extends StatelessWidget {
  const _NoSearchResultsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "No patients match your search.",
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
