import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import 'package:genex_app/l10n/app_localizations.dart';
import '../../widgets/premium_card.dart';
//done

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final reportsAsync =
        ref.watch(geneReportsProvider);

    final theme = Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            theme.appBarTheme
                .backgroundColor,
        foregroundColor:
            theme.colorScheme
                .onSurface,
        title: Text(
          loc.medicalAnalysisHistory,
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            color: theme
                .colorScheme
                .onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            geneReportsProvider,
          );

          await ref.read(
            geneReportsProvider.future,
          );
        },
        child: reportsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          ),
          error:
              (err, stack) => Center(
            child: Text(
              loc.errorLoadingReports(
                err.toString(),
              ),
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return _buildEmptyState(
                context,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
                  reports.length,
              itemBuilder:
                  (context, index) {
                final report =
                    reports[index];

                return _ReportCard(
                  report: report,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
  final theme = Theme.of(context);
  final loc = AppLocalizations.of(context)!;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: PremiumCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              loc.noReportsFound,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.uploadGeneFileMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.62),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}}

class _ReportCard extends StatelessWidget {
  final dynamic report;

  const _ReportCard({
    required this.report,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final loc =
        AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    final String resultLabel =
        report['label']
                ?.toString() ??
            loc.unknown;

    final bool isHighRisk =
        resultLabel.contains(
      "High",
    );

    final Color statusColor =
        isHighRisk
            ? Colors.redAccent
            : Colors.green;

    final double riskPercentage =
        ((report['percentage']
                    as num?)
                ?.toDouble() ??
            0.0);

    final String fileName =
        report['filename']
                ?.toString() ??
            loc.unknown;

    final String createdAt =
        report['date']
                ?.toString() ??
            '';

    final String formattedDate =
        createdAt.length >= 10
            ? createdAt.substring(
                0,
                10,
              )
            : createdAt;

    final dynamic topGenesRaw =
        report[
            'top_affecting_genes'];

    final Map<String, dynamic>
        topGenes =
        topGenesRaw
                is Map<String,
                    dynamic>
            ? topGenesRaw
            : {};

    return Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: PremiumCard(
    padding: EdgeInsets.zero,
    child: Theme(
        data: Theme.of(context)
            .copyWith(
          dividerColor:
              Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            padding:
                const EdgeInsets.all(
                    8),
            decoration: BoxDecoration(
              color: statusColor
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: statusColor,
            ),
          ),

          title: Text(
            resultLabel,
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: statusColor,
            ),
          ),

          subtitle: Text(
            "${loc.file}: $fileName",
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7),
            ),
          ),

          trailing: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            crossAxisAlignment:
                CrossAxisAlignment
                    .end,
            children: [
              Text(
                "${riskPercentage.toStringAsFixed(1)}%",
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              Text(
                loc.risk,
                style:
                    const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          children: [
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                      16.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  const SizedBox(height: 16),
                  const Divider(),

                  const SizedBox(
                      height: 8),

                  Text(
                    loc
                        .topGeneticDrivers,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                      fontSize: 14,
                    ),
                  ),

                  Text(
                    loc
                        .geneImpactDescription,
                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey,
                    ),
                  ),

                  const SizedBox(
                      height: 12),

                  topGenes.isEmpty
                      ? Text(
                          loc
                              .noGeneImportanceData,
                          style:
                              const TextStyle(
                            fontSize:
                                12,
                            color: Colors
                                .grey,
                          ),
                        )
                      : Wrap(
                          spacing:
                              8,
                          runSpacing:
                              8,
                          children:
                              topGenes.entries.map(
                            (entry) {
                              final double
                                  val =
                                  (entry.value
                                              as num?)
                                          ?.toDouble() ??
                                      0.0;

                              final Color
                                  geneColor =
                                  val >= 0
                                      ? Colors.red
                                      : Colors.blue;

                              return Chip(
                                visualDensity:
                                    VisualDensity.compact,
                                backgroundColor:
                                    geneColor.withOpacity(
                                  0.1,
                                ),
                                side:
                                    BorderSide(
                                  color:
                                      geneColor.withOpacity(
                                    0.2,
                                  ),
                                ),
                                label:
                                    Text(
                                  "${entry.key}: ${val > 0 ? '+' : ''}${val.toStringAsFixed(2)}",
                                ),
                                labelStyle:
                                    TextStyle(
                                  fontSize:
                                      11,
                                  color:
                                      geneColor,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              );
                            },
                          ).toList(),
                        ),

                  const SizedBox(
                      height: 16),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today,
                        size: 14,
                        color:
                            Colors.grey,
                      ),

                      const SizedBox(
                          width: 6),

                      Text(
                        "${loc.date}: $formattedDate",
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey,
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
  Widget build(
    BuildContext context,
  ) {
    final double numericValue =
        (value as num?)
                ?.toDouble() ??
            0.0;

    final double clampedValue =
        numericValue.clamp(
      0.0,
      1.0,
    );

    final String displayValue =
        value != null
            ? "${(numericValue * 100).toStringAsFixed(1)}%"
            : "N/A";

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child:
                LinearProgressIndicator(
              value: clampedValue,
              backgroundColor:
                  color.withOpacity(
                0.1,
              ),
              color: color,
              minHeight: 6,
              borderRadius:
                  BorderRadius.circular(
                      10),
            ),
          ),

          const SizedBox(width: 12),

          Text(
            displayValue,
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}