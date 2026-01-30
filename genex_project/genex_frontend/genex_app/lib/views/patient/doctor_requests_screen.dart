import 'package:flutter/material.dart';

enum RequestStatus { pending, accepted, rejected }

class DoctorRequest {
  final String doctorName;
  final DateTime time;
  RequestStatus status;

  DoctorRequest({
    required this.doctorName,
    required this.time,
    this.status = RequestStatus.pending,
  });
}

class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  // Demo data (replace with API/Riverpod later)
  final List<DoctorRequest> requests = [
    DoctorRequest(doctorName: "Dr. Ahmed Hassan", time: DateTime.now().add(const Duration(hours: 2))),
    DoctorRequest(doctorName: "Dr. Sara Ali", time: DateTime.now().add(const Duration(days: 1))),
    DoctorRequest(doctorName: "Dr. Omar Adel", time: DateTime.now().add(const Duration(days: 2, hours: 3))),
  ];

  String _formatTime(DateTime dt) {
    // Simple formatting without intl
    final two = (int n) => n.toString().padLeft(2, '0');
    return "${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}";
  }

  String _statusText(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:
        return "Pending";
      case RequestStatus.accepted:
        return "Accepted";
      case RequestStatus.rejected:
        return "Rejected";
    }
  }

  Color _statusColor(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
    }
  }

  void _accept(int index) {
    setState(() {
      requests[index].status = RequestStatus.accepted;
    });
  }

  void _reject(int index) {
    setState(() {
      requests[index].status = RequestStatus.rejected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Doctor Name")),
                  DataColumn(label: Text("Time")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Action")),
                ],
                rows: List.generate(requests.length, (index) {
                  final r = requests[index];
                  final decided = r.status != RequestStatus.pending;

                  return DataRow(
                    cells: [
                      DataCell(Text(r.doctorName)),
                      DataCell(Text(_formatTime(r.time))),
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
                      DataCell(
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: decided ? null : () => _accept(index),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              child: const Text("Accept", style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: decided ? null : () => _reject(index),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    );
  }
}
