// lib/patient/home_view.dart
import 'package:flutter/material.dart';
import 'upload_screen.dart';
import 'med_history_screen.dart';
import 'twin_simulation_screen.dart';
import 'profile_view.dart';  // Import ProfileScreen


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.health_and_safety, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Welcome to the Patient Portal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the tabs below to view your profile, add medicine history, or upload files.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Profile Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProfileScreen(), // Navigate to ProfileScreen
                  ));
                },
                child: const Text('View Profile'),  // Profile button label
              ),
              
              const SizedBox(height: 16),
              // File Upload Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const UploadScreen(),
                  ));
                },
                child: const Text('Upload File'),
              ),
              const SizedBox(height: 16),
              // Medicine History Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MedHistoryScreen(),
                  ));
                },
                child: const Text('Medicine History'),
              ),
              const SizedBox(height: 16),
              // Twin Simulation Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const TwinSimulationScreen(),
                  ));
                },
                child: const Text('Twin Simulation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
