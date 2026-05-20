import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genex_app/l10n/app_localizations.dart';
//done
class DoctorRequest {
  final int id;
  final String doctorName;
  final String date;
  String status;

  DoctorRequest({
    required this.id,
    required this.doctorName,
    required this.date,
    required this.status,
  });

  factory DoctorRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    return DoctorRequest(
      id: json['id'],
      doctorName:
          json['doctor_name'] ??
              'Unknown Doctor',
      date: json['date'] ?? '',
      status:
          json['status'] ??
              'pending',
    );
  }
}

class DoctorRequestsScreen
    extends StatefulWidget {
  const DoctorRequestsScreen({
    super.key,
  });

  @override
  State<DoctorRequestsScreen>
      createState() =>
          _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState
    extends State<
        DoctorRequestsScreen> {
  List<DoctorRequest> requests =
      [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    debugPrint(
      "🔵 STARTING: _fetchRequests called",
    );

    final prefs =
        await SharedPreferences
            .getInstance();

    final token =
        prefs.getString('token');

    debugPrint(
      "🔑 Token found: ${token != null ? 'YES' : 'NO (NULL)'}",
    );

    if (token == null) {
      debugPrint(
        "❌ ABORTING: No token found.",
      );

      setState(
        () => _isLoading = false,
      );

      return;
    }

    final url = Uri.parse(
      'http://127.0.0.1:8000/api/patient/requests/',
    );

    try {
      debugPrint(
        "🚀 SENDING REQUEST TO: $url",
      );

      final response =
          await http.get(
        url,
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      );

      debugPrint(
        "📡 SERVER RESPONSE CODE: ${response.statusCode}",
      );

      if (response.statusCode ==
          200) {
        debugPrint(
          "📦 DATA RECEIVED: ${response.body}",
        );

        final List<dynamic> data =
            jsonDecode(response.body);

        setState(() {
          requests = data
              .map(
                (json) =>
                    DoctorRequest
                        .fromJson(
                  json,
                ),
              )
              .toList();

          _isLoading = false;
        });
      } else {
        debugPrint(
          "⚠️ SERVER ERROR: ${response.body}",
        );

        setState(
          () => _isLoading = false,
        );
      }
    } catch (e) {
      debugPrint(
        "❌ CLIENT CONNECTION ERROR: $e",
      );

      setState(
        () => _isLoading = false,
      );
    }
  }

  Future<void> _updateStatus(
    int requestId,
    String action,
    int index,
  ) async {
    final loc =
        AppLocalizations.of(context)!;

    final prefs =
        await SharedPreferences
            .getInstance();

    final token =
        prefs.getString('token');

    final url = Uri.parse(
      'http://127.0.0.1:8000/api/patient/requests/$requestId/update/',
    );

    try {
      final response =
          await http.post(
        url,
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
        body: jsonEncode({
          'action': action,
        }),
      );

      if (response.statusCode ==
          200) {
        setState(() {
          requests[index].status =
              (action == 'accept')
                  ? 'accepted'
                  : 'rejected';
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              action == 'accept'
                  ? loc.requestAcceptedSuccessfully
                  : loc.requestRejectedSuccessfully,
            ),
            backgroundColor:
                action == 'accept'
                    ? Colors.green
                    : Colors.red,
          ),
        );
      } else {
        debugPrint(
          "Server Error: ${response.body}",
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              loc.failedToUpdateStatus,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        "Error updating: $e",
      );
    }
  }

  String _statusText(
    String s,
    BuildContext context,
  ) {
    final loc =
        AppLocalizations.of(context)!;

    if (s == 'pending') {
      return loc.pending;
    }

    if (s == 'accepted') {
      return loc.accepted;
    }

    if (s == 'rejected') {
      return loc.rejected;
    }

    return s;
  }

  Color _statusColor(String s) {
    if (s == 'pending') {
      return Colors.orange;
    }

    if (s == 'accepted') {
      return Colors.green;
    }

    if (s == 'rejected') {
      return Colors.red;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final loc =
        AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.accessRequests,
          style: TextStyle(
            color:
                theme.colorScheme.onSurface,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              loc.doctorRequests,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding:
                  const EdgeInsets.all(
                      16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surface,
                borderRadius:
                    BorderRadius.circular(
                        12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                            0.05),
                    blurRadius: 10,
                    offset:
                        const Offset(
                            0, 4),
                  ),
                ],
              ),
              child: requests.isEmpty
                  ? Padding(
                      padding:
                          const EdgeInsets
                              .all(20),
                      child: Text(
                        loc
                            .noRequestsFound,
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(
                            label: Text(
                              loc
                                  .doctorName,
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              loc.date,
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              loc.status,
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              loc.action,
                            ),
                          ),
                        ],
                        rows:
                            List.generate(
                          requests.length,
                          (index) {
                            final r =
                                requests[
                                    index];

                            final isPending =
                                r.status ==
                                    'pending';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    r.doctorName,
                                  ),
                                ),

                                DataCell(
                                  Text(
                                    r.date,
                                  ),
                                ),

                                DataCell(
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          10,
                                      vertical:
                                          6,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: _statusColor(
                                        r.status,
                                      ).withOpacity(
                                          0.12),
                                      borderRadius:
                                          BorderRadius.circular(
                                              999),
                                      border:
                                          Border.all(
                                        color: _statusColor(
                                          r.status,
                                        ).withOpacity(
                                            0.35),
                                      ),
                                    ),
                                    child:
                                        Text(
                                      _statusText(
                                        r.status,
                                        context,
                                      ),
                                      style:
                                          TextStyle(
                                        color: _statusColor(
                                          r.status,
                                        ),
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                DataCell(
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed:
                                            isPending
                                                ? () => _updateStatus(
                                                      r.id,
                                                      'accept',
                                                      index,
                                                    )
                                                : null,
                                        style:
                                            ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.teal,
                                          disabledBackgroundColor:
                                              Colors.grey[200],
                                        ),
                                        child:
                                            Text(
                                          loc
                                              .accept,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.white,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              10),

                                      ElevatedButton(
                                        onPressed:
                                            isPending
                                                ? () => _updateStatus(
                                                      r.id,
                                                      'reject',
                                                      index,
                                                    )
                                                : null,
                                        style:
                                            ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.red,
                                          disabledBackgroundColor:
                                              Colors.grey[200],
                                        ),
                                        child:
                                            Text(
                                          loc
                                              .reject,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
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