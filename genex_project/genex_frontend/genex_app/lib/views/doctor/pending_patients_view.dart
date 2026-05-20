import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import 'package:genex_app/l10n/app_localizations.dart';
//done
class PendingPatientsView extends ConsumerStatefulWidget {
  const PendingPatientsView({super.key});

  @override
  ConsumerState<PendingPatientsView> createState() =>
      _PendingPatientsViewState();
}

class _PendingPatientsViewState
    extends ConsumerState<PendingPatientsView> {
  static const Color mainBlue =
      Color(0xFF1A5699);

  bool isLoading = true;

  List<dynamic> pendingPatients = [];

  @override
  void initState() {
    super.initState();
    fetchPendingPatients();
  }

  Future<void> fetchPendingPatients() async {
    try {
      final api =
          ref.read(apiServiceProvider);

      final response = await api.get(
        '/doctor/pending-patients/',
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingPatients =
              response.data['patients'] ??
                  [];

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        '❌ Error fetching pending patients: $e',
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });

    await fetchPendingPatients();
  }

  String getDisplayName(
    Map<String, dynamic> patient,
  ) {
    final firstName =
        (patient['first_name'] ?? '')
            .toString()
            .trim();

    final lastName =
        (patient['last_name'] ?? '')
            .toString()
            .trim();

    if (firstName.isNotEmpty ||
        lastName.isNotEmpty) {
      return '$firstName $lastName'
          .trim();
    }

    return (patient['username'] ??
            'Unknown Patient')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final loc =
        AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.pendingPatients,
          style: TextStyle(
            color:
                theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor:
            theme.appBarTheme
                .backgroundColor,
        foregroundColor:
            theme.appBarTheme
                .foregroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : pendingPatients.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(
                          height: 180),
                      Center(
                        child: Text(
                          loc
                              .noPendingPatientsFound,
                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.all(
                            16),
                    itemCount:
                        pendingPatients.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 12,
                    ),
                    itemBuilder:
                        (context, index) {
                      final patient =
                          Map<String,
                              dynamic>.from(
                        pendingPatients[
                            index],
                      );

                      return Container(
                        padding:
                            const EdgeInsets
                                .all(16),
                        decoration:
                            BoxDecoration(
                          color: theme
                              .colorScheme
                              .surface,
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      14),
                          border: Border.all(
                            color: theme
                                .dividerColor
                                .withOpacity(
                                    0.15),
                          ),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withOpacity(
                                        0.05),
                                blurRadius: 8,
                                offset:
                                    const Offset(
                                        0,
                                        2),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  theme
                                      .colorScheme
                                      .primary
                                      .withOpacity(
                                          0.12),
                              child: Icon(
                                Icons
                                    .person_outline,
                                color: theme
                                    .colorScheme
                                    .primary,
                              ),
                            ),
                            const SizedBox(
                                width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    getDisplayName(
                                      patient,
                                    ),
                                    style:
                                        TextStyle(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: theme
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(
                                      height:
                                          4),
                                  Text(
                                    (patient[
                                                'email'] ??
                                            '')
                                        .toString(),
                                    style:
                                        TextStyle(
                                      fontSize:
                                          13,
                                      color: theme
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(
                                              0.65),
                                    ),
                                  ),
                                  const SizedBox(
                                      height:
                                          4),
                                  Text(
                                    '${loc.status}: ${(patient['status'] ?? 'pending').toString()}',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          13,
                                      color: Colors
                                          .orange
                                          .shade400,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                  if ((patient['appointment_date'] ??
                                          '')
                                      .toString()
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                        height:
                                            4),
                                    Text(
                                      '${loc.appointment}: ${patient['appointment_date']}',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            13,
                                        color: theme
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(
                                                0.65),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}