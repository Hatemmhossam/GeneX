import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ MODEL: Uses String for status now (No Enum)
class DoctorRequest {
  final int id;
  final String doctorName;
  final String date;
  String status; // 'pending', 'accepted', 'rejected'

  DoctorRequest({
    required this.id,
    required this.doctorName,
    required this.date,
    required this.status,
  });

  factory DoctorRequest.fromJson(Map<String, dynamic> json) {
    return DoctorRequest(
      id: json['id'],
      doctorName: json['doctor_name'] ?? 'Unknown Doctor',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  List<DoctorRequest> requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  // --- API CALLS ---
  Future<void> _fetchRequests() async {
    debugPrint("🔵 STARTING: _fetchRequests called");
    
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ FIX 1: Use 'token', not 'access' (This was the main bug!)
    final token = prefs.getString('token'); 

    debugPrint("🔑 Token found: ${token != null ? 'YES' : 'NO (NULL)'}");

    if (token == null) {
      debugPrint("❌ ABORTING: No token found. User might not be logged in.");
      setState(() => _isLoading = false);
      return;
    }

    // ✅ FIX 2: Ensure correct URL for Web/Chrome
    final url = Uri.parse('http://127.0.0.1:8000/api/patient/requests/'); 

    try {
      debugPrint("🚀 SENDING REQUEST TO: $url");
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // JWT Standard
        },
      );

      debugPrint("📡 SERVER RESPONSE CODE: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        debugPrint("📦 DATA RECEIVED: ${response.body}");
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          requests = data.map((json) => DoctorRequest.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        debugPrint("⚠️ SERVER ERROR: ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // ✅ This is where the error was hiding!
      debugPrint("❌ CLIENT CONNECTION ERROR: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int requestId, String action, int index) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. FIX KEY: Use 'token', not 'access'
    final token = prefs.getString('token'); 

    // 2. FIX URL: Ensure it points to localhost (Chrome)
    final url = Uri.parse('http://127.0.0.1:8000/api/patient/requests/$requestId/update/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // 3. FIX HEADER: Must be 'Bearer', not 'Token'
          'Authorization': 'Bearer $token' 
        },
        body: jsonEncode({'action': action}),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Update the list visually immediately
          requests[index].status = (action == 'accept') ? 'accepted' : 'rejected';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Request ${action}ed successfully!"),
            backgroundColor: action == 'accept' ? Colors.green : Colors.red,
          ),
        );
      } else {
        debugPrint("Server Error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Failed to update status. Check console.")),
        );
      }
    } catch (e) {
      debugPrint("Error updating: $e");
    }
  }

  // --- UI HELPERS (Now checking Strings) ---
  String _statusText(String s) {
    if (s == 'pending') return "Pending";
    if (s == 'accepted') return "Accepted";
    if (s == 'rejected') return "Rejected";
    return s; // Fallback
  }

  Color _statusColor(String s) {
    if (s == 'pending') return Colors.orange;
    if (s == 'accepted') return Colors.green;
    if (s == 'rejected') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Access Requests")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Doctor Requests",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: requests.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(20), 
                  child: Text("No requests found.")
                )
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Doctor Name")),
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: List.generate(requests.length, (index) {
                    final r = requests[index];
                    final isPending = r.status == 'pending'; // Check string directly

                    return DataRow(
                      cells: [
                        DataCell(Text(r.doctorName)),
                        DataCell(Text(r.date)),
                        // Status Badge
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor(r.status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _statusColor(r.status).withOpacity(0.35)),
                            ),
                            child: Text(
                              _statusText(r.status),
                              style: TextStyle(
                                color: _statusColor(r.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Action Buttons
                        DataCell(
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: isPending ? () => _updateStatus(r.id, 'accept', index) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  disabledBackgroundColor: Colors.grey[200],
                                ),
                                child: const Text("Accept", style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: isPending ? () => _updateStatus(r.id, 'reject', index) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  disabledBackgroundColor: Colors.grey[200],
                                ),
                                child: const Text("Reject", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}