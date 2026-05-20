import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assigned_doctor_model.dart';
import '../../viewmodels/providers.dart';
import '../shared/chat_screen.dart';
import 'package:genex_app/l10n/app_localizations.dart';
//done

class MyDoctorsScreen extends ConsumerStatefulWidget {
  const MyDoctorsScreen({super.key});

  @override
  ConsumerState<MyDoctorsScreen> createState() => _MyDoctorsScreenState();
}

class _MyDoctorsScreenState extends ConsumerState<MyDoctorsScreen> {
  bool isLoading = true;
  List<AssignedDoctorModel> doctors = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final result = await chatService.getAssignedDoctors();

      setState(() {
        doctors = result;
        error = null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _openChat(AssignedDoctorModel doctor) async {
    final loc = AppLocalizations.of(context)!;

    try {
      final authState = ref.read(authViewModelProvider);

      final rawPatientId = authState.user?.id;
      final patientId = int.tryParse(rawPatientId?.toString() ?? '');

      if (patientId == null) {
        throw Exception(loc.patientIdInvalid);
      }

      final chatService = ref.read(chatServiceProvider);

      final conversation = await chatService.openConversation(
        doctorId: doctor.doctorId,
        patientId: patientId,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            receiverName: doctor.doctorName.isNotEmpty
                ? doctor.doctorName
                : doctor.doctorUsername,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.failedToOpenChat(e.toString()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text(
          loc.myDoctors,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                )
              : doctors.isEmpty
                  ? Center(
                      child: Text(
                        loc.noAssignedDoctorsFound,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];

                        return Card(
                          color: theme.colorScheme.surface,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(0.15),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primary.withOpacity(0.12),
                              child: Icon(
                                Icons.medical_services_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              doctor.doctorName.isNotEmpty
                                  ? doctor.doctorName
                                  : doctor.doctorUsername,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              doctor.doctorUsername,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.65),
                              ),
                            ),
                            trailing: ElevatedButton.icon(
                              onPressed: () => _openChat(doctor),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(loc.chat),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}