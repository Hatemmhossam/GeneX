import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import 'my_doctors_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _sortOption = 'riskHighLow';

  List<dynamic> _sortReports(List<dynamic> reports) {
    final sorted = [...reports];

    switch (_sortOption) {
      case 'riskLowHigh':
        sorted.sort((a, b) {
          final aRisk = ((a['percentage'] as num?)?.toDouble() ?? 0.0);
          final bRisk = ((b['percentage'] as num?)?.toDouble() ?? 0.0);
          return aRisk.compareTo(bRisk);
        });
        break;

      case 'dateNewest':
        sorted.sort((a, b) {
          final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['date']?.toString() ?? '');

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return bDate.compareTo(aDate);
        });
        break;

      case 'dateOldest':
        sorted.sort((a, b) {
          final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['date']?.toString() ?? '');

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return aDate.compareTo(bDate);
        });
        break;

      case 'fileAZ':
        sorted.sort((a, b) {
          final aName = a['filename']?.toString().toLowerCase() ?? '';
          final bName = b['filename']?.toString().toLowerCase() ?? '';
          return aName.compareTo(bName);
        });
        break;

      case 'fileZA':
        sorted.sort((a, b) {
          final aName = a['filename']?.toString().toLowerCase() ?? '';
          final bName = b['filename']?.toString().toLowerCase() ?? '';
          return bName.compareTo(aName);
        });
        break;

      case 'riskHighLow':
      default:
        sorted.sort((a, b) {
          final aRisk = ((a['percentage'] as num?)?.toDouble() ?? 0.0);
          final bRisk = ((b['percentage'] as num?)?.toDouble() ?? 0.0);
          return bRisk.compareTo(aRisk);
        });
        break;
    }

    return sorted;
  }

  Widget _buildSortDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Sort by:",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          DropdownButton<String>(
            value: _sortOption,
            borderRadius: BorderRadius.circular(12),
            items: const [
              DropdownMenuItem(
                value: 'riskHighLow',
                child: Text('Risk: High to Low'),
              ),
              DropdownMenuItem(
                value: 'riskLowHigh',
                child: Text('Risk: Low to High'),
              ),
              DropdownMenuItem(
                value: 'dateNewest',
                child: Text('Date: Newest to Oldest'),
              ),
              DropdownMenuItem(
                value: 'dateOldest',
                child: Text('Date: Oldest to Newest'),
              ),
              DropdownMenuItem(value: 'fileAZ', child: Text('File Name: A-Z')),
              DropdownMenuItem(value: 'fileZA', child: Text('File Name: Z-A')),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _sortOption = value;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(geneReportsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Medical Analysis History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(geneReportsProvider);
          await ref.read(geneReportsProvider.future);
        },
        child: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              "Error loading reports: $err",
              style: const TextStyle(color: Colors.red),
            ),
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return _buildEmptyState();
            }

            final sortedReports = _sortReports(reports);

            return Column(
              children: [
                _buildSortDropdown(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sortedReports.length,
                    itemBuilder: (context, index) {
                      final report = sortedReports[index];
                      return _ReportCard(report: report);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No reports found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const Text(
            "Upload a gene file to see results here.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final dynamic report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String resultLabel = report['label']?.toString() ?? 'Unknown';
    final bool isHighRisk = resultLabel.contains("High");
    final Color statusColor = isHighRisk ? Colors.redAccent : Colors.green;

    final double riskPercentage =
        ((report['percentage'] as num?)?.toDouble() ?? 0.0);

    final String fileName = report['filename']?.toString() ?? 'Unknown';

    final String createdAt = report['date']?.toString() ?? '';
    final String formattedDate = createdAt.length >= 10
        ? createdAt.substring(0, 10)
        : createdAt;

    final bool canViewResult = report['doctor_permission'] == true;
    final String permissionStatus =
        report['permission_status']?.toString() ?? 'not_requested';

    final dynamic topGenesRaw = report['top_affecting_genes'];
    final Map<String, dynamic> topGenes = topGenesRaw is Map<String, dynamic>
        ? topGenesRaw
        : {};

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              canViewResult ? Icons.biotech : Icons.lock_outline,
              color: canViewResult ? statusColor : Colors.orange,
            ),
          ),
          title: Text(
            canViewResult ? resultLabel : "Result Locked",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: canViewResult ? statusColor : Colors.orange,
            ),
          ),
          subtitle: Text("File: $fileName"),
          trailing: canViewResult
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${riskPercentage.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "Risk",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                )
              : const Icon(Icons.lock, color: Colors.orange),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),

            if (!canViewResult)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 45,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Doctor Permission Required",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      permissionStatus == 'pending'
                          ? "Your request is waiting for doctor approval."
                          : permissionStatus == 'declined'
                          ? "Your doctor declined access to this result."
                          : "You must ask your doctor from the chat screen before seeing this result.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MyDoctorsScreen(reportId: report['id']),
                          ),
                        );

                        ref.invalidate(geneReportsProvider);
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Ask Doctor from Chat"),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Top Genetic Drivers (SHAP)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      "Impact of specific genes on this prediction",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    topGenes.isEmpty
                        ? const Text(
                            "No gene importance data available",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: topGenes.entries.map((entry) {
                              final double val =
                                  (entry.value as num?)?.toDouble() ?? 0.0;
                              final Color geneColor = val >= 0
                                  ? Colors.red
                                  : Colors.blue;

                              return Chip(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: geneColor.withOpacity(0.1),
                                side: BorderSide(
                                  color: geneColor.withOpacity(0.2),
                                ),
                                label: Text(
                                  "${entry.key}: ${val > 0 ? '+' : ''}${val.toStringAsFixed(2)}",
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: geneColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Date: $formattedDate",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double numericValue = (value as num?)?.toDouble() ?? 0.0;
    final double clampedValue = numericValue.clamp(0.0, 1.0);

    final String displayValue = value != null
        ? "${(numericValue * 100).toStringAsFixed(1)}%"
        : "N/A";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: clampedValue,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            displayValue,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
