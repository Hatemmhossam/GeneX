import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart'; 
import 'profile_view.dart';
import 'upload_screen.dart';
import 'med_history_screen.dart';
import 'twin_simulation_screen.dart';

class ResponsiveDashboard extends ConsumerStatefulWidget {
  const ResponsiveDashboard({super.key});

  @override
  ConsumerState<ResponsiveDashboard> createState() => _ResponsiveDashboardState();
}

class _ResponsiveDashboardState extends ConsumerState<ResponsiveDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverview(), 
    const ProfileScreen(),
    const MedHistoryScreen(),
    const UploadScreen(),
    const TwinSimulationScreen(),
  ];

  void _handleLogout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of the GeneX portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authViewModelProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended: width > 1200,
              backgroundColor: const Color(0xFFF8FAFC),
              selectedIconTheme: const IconThemeData(color: Colors.teal),
              unselectedIconTheme: const IconThemeData(color: Colors.grey),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Overview')),
                NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
                NavigationRailDestination(icon: Icon(Icons.medication), label: Text('History')),
                NavigationRailDestination(icon: Icon(Icons.upload_file), label: Text('Upload')),
                NavigationRailDestination(icon: Icon(Icons.biotech), label: Text('Simulation')),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              // REMOVED: The 'trailing' property that contained the bottom logout button
            ),
          
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop ? BottomNavigationBar(
        currentIndex: _selectedIndex > 2 ? 0 : _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Meds'),
        ],
      ) : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text("GeneX Medical Portal", 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
          const Spacer(),
          // KEEPING THIS ONE: The logout button in the top right
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _handleLogout, 
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Colors.teal.shade50, 
            child: const Icon(Icons.person, color: Colors.teal),
          ),
        ],
      ),
    );
  }
} // <--- End of State class

// --- DashboardOverview is now outside to fix the red error ---

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("System Overview", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
            shrinkWrap: true,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _medicalWidget("Vitals Status", "Stable", Icons.favorite, Colors.red),
              _medicalWidget("Active Meds", "4 Prescribed", Icons.medication, Colors.blue),
              _medicalWidget("Next Simulation", "Scheduled: Jan 30", Icons.science, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medicalWidget(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}