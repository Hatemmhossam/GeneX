import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(geneReportsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Medical Analysis History",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(geneReportsProvider.future),
        child: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text("Error loading reports: $err",
                style: const TextStyle(color: Colors.red)),
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportCard(report: report);
              },
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
          const Text("No reports found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const Text("Upload a gene file to see results here.",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final dynamic report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final bool isHighRisk = report['label'].toString().contains("High");
    final Color statusColor = isHighRisk ? Colors.redAccent : Colors.green;

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
            child: Icon(Icons.biotech, color: statusColor),
          ),
          title: Text(
            report['label'],
            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
          ),
          subtitle: Text("File: ${report['filename'] ?? 'Unknown'}"),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${report['percentage']}%",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text("Probability", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Model Classification Report",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _MetricRow(label: "Precision", value: report['precision'], color: Colors.blue),
                  _MetricRow(label: "Recall", value: report['recall'], color: Colors.orange),
                  _MetricRow(label: "F1-Score", value: report['f1_score'], color: Colors.purple),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text("Top Genetic Drivers (SHAP)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text("Impact of specific genes on this prediction",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),

                  // Fixed Wrap: Now inside the Column, not a Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (report['top_affecting_genes'] as Map<String, dynamic>? ?? {})
                        .entries
                        .map((entry) {
                          // Red if SHAP > 0 (increases risk), Blue if SHAP < 0 (decreases risk)
                          final double val = (entry.value as num).toDouble();
                          final Color geneColor = val >= 0 ? Colors.red : Colors.blue;
                          
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: geneColor.withOpacity(0.1),
                            side: BorderSide(color: geneColor.withOpacity(0.2)),
                            label: Text("${entry.key}: ${val > 0 ? '+' : ''}${val.toStringAsFixed(2)}"),
                            labelStyle: TextStyle(fontSize: 11, color: geneColor, fontWeight: FontWeight.bold),
                          );
                        })
                        .toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text("Date: ${report['date']}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            )
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

  const _MetricRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    String displayValue = (value != null)
        ? "${(value * 100).toStringAsFixed(1)}%"
        : "N/A";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: LinearProgressIndicator(
              value: (value ?? 0).toDouble(),
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Text(displayValue,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}