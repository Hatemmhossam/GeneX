import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assigned_doctor_model.dart';
import '../../viewmodels/providers.dart';
import '../shared/chat_screen.dart';

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
    try {
      final authState = ref.read(authViewModelProvider);

      final rawPatientId = authState.user?.id;
      final patientId = int.tryParse(rawPatientId?.toString() ?? '');

      if (patientId == null) {
        throw Exception('Patient ID not found or invalid');
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
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Doctors'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : doctors.isEmpty
                  ? const Center(child: Text('No assigned doctors found'))
                  : ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.medical_services_outlined),
                            ),
                            title: Text(
                              doctor.doctorName.isNotEmpty
                                  ? doctor.doctorName
                                  : doctor.doctorUsername,
                            ),
                            subtitle: Text(doctor.doctorUsername),
                            trailing: ElevatedButton.icon(
                              onPressed: () => _openChat(doctor),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Chat'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}