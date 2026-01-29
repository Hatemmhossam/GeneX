import 'package:flutter/material.dart';

class AboutSystemScreen extends StatelessWidget {
  const AboutSystemScreen({super.key});

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: (color ?? Colors.teal).withOpacity(0.1),
            child: Icon(icon, color: color ?? Colors.teal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Important Medical Disclaimer",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                SizedBox(height: 6),
                Text(
                  "This application is NOT a replacement for professional medical care. "
                  "It helps patients organize their medical history, track medications, "
                  "and communicate with their doctors, but it cannot diagnose or treat any condition. "
                  "Always consult a qualified physician before making medical decisions.",
                  style: TextStyle(color: Colors.red, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("About the System"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              icon: Icons.psychology,
              title: "Purpose",
              content:
                  "This system is designed to help patients with the diagnosis process and provide quick connection with their doctors. "
                  "Patients can access the descriptions and notes entered by their doctors.",
              color: Colors.teal,
            ),
            _sectionCard(
              icon: Icons.star,
              title: "Main Features",
              content:
                  "• Easy data entry for patients\n"
                  "• Doctors can access patient data and enter prescriptions\n"
                  "• Patients can track all taken medications\n"
                  "• Import medical history to organize all information about medications and treatments",
              color: Colors.blue,
            ),
            _sectionCard(
              icon: Icons.settings,
              title: "How the System Works",
              content:
                  "The system works by importing patient files, allowing doctors to view patient reports and select the best medications. "
                  "It is designed to provide guidance with high accuracy in medication suggestions.",
              color: Colors.deepPurple,
            ),
            _sectionCard(
              icon: Icons.info_outline,
              title: "Limitations",
              content:
                  "This system provides assistance and organization for medical information, but it cannot replace professional medical advice. "
                  "The recommendations are supportive and should always be verified by a qualified doctor.",
              color: Colors.orange,
            ),
            _disclaimerCard(),
          ],
        ),
      ),
    );
  }
}