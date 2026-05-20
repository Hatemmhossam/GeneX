import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/user_search_state.dart';
import 'package:genex_app/l10n/app_localizations.dart';
//done
class UserSearchView extends ConsumerStatefulWidget {
  const UserSearchView({super.key});

  @override
  ConsumerState<UserSearchView> createState() =>
      _UserSearchViewState();
}

class _UserSearchViewState
    extends ConsumerState<UserSearchView> {
  final _ctr = TextEditingController();
  Timer? _debounce;

  final bool _useDebounce = true;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctr.dispose();
    super.dispose();
  }

  void _triggerSearch(String value) {
    ref
        .read(userSearchViewModelProvider.notifier)
        .search(value);
  }

  void _onChanged(String value) {
    if (!_useDebounce) {
      _triggerSearch(value);
      return;
    }

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () {
        _triggerSearch(value);
      },
    );
  }

  Future<void> _showAddPatientDialog(
    BuildContext context,
    String username,
    dynamic vm,
  ) async {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              color:
                  theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              loc.addPatient,
              style: TextStyle(
                color: theme
                    .colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          loc.addPatientQuestion(username),
          style: TextStyle(
            fontSize: 15,
            color: theme
                .colorScheme.onSurface
                .withOpacity(0.75),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    loc.sendingRequest,
                  ),
                  behavior:
                      SnackBarBehavior
                          .floating,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(14),
                  ),
                ),
              );

              final success =
                  await vm.sendAddRequest(
                username,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(
                        context)
                    .hideCurrentSnackBar();

                ScaffoldMessenger.of(
                        context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? loc.requestSent(
                              username)
                          : loc
                              .requestFailed,
                    ),
                    backgroundColor:
                        success
                            ? Colors.green
                            : Colors.red,
                    behavior:
                        SnackBarBehavior
                            .floating,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  14),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(
              Icons.send_rounded,
            ),
            label: Text(loc.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(userSearchViewModelProvider);

    final vm = ref.read(
      userSearchViewModelProvider.notifier,
    );

    final theme = Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final isTyping =
        _ctr.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor:
            theme.appBarTheme.backgroundColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor,
        title: Text(
          loc.searchPatients,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                12,
              ),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(
                  bottom:
                      Radius.circular(24),
                ),
                boxShadow: [
                  if (!isDark)
                    const BoxShadow(
                      color:
                          Color(0x11000000),
                      blurRadius: 12,
                      offset:
                          Offset(0, 4),
                    ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: theme
                        .dividerColor
                        .withOpacity(0.15),
                  ),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _ctr,
                    textDirection:
                        Directionality.of(
                            context),
                    style: TextStyle(
                      color: theme
                          .colorScheme
                          .onSurface,
                    ),
                    onChanged: (v) {
                      setState(() {});
                      _onChanged(v);
                    },
                    decoration:
                        InputDecoration(
                      hintText: loc
                          .searchByPatientUsername,
                      hintStyle:
                          TextStyle(
                        color: theme
                            .colorScheme
                            .onSurface
                            .withOpacity(
                                0.5),
                      ),
                      prefixIcon: Icon(
                        Icons
                            .search_rounded,
                        color: theme
                            .colorScheme
                            .primary,
                      ),
                      suffixIcon:
                          _ctr.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(
                                    Icons
                                        .close_rounded,
                                    color: theme
                                        .colorScheme
                                        .primary,
                                  ),
                                  onPressed:
                                      () {
                                    _ctr.clear();

                                    _debounce
                                        ?.cancel();

                                    vm.clear();

                                    setState(
                                        () {});
                                  },
                                ),
                      filled: true,
                      fillColor: theme
                          .inputDecorationTheme
                          .fillColor,
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    18),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 12),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons
                            .analytics_outlined,
                        label: loc.status,
                        value: state
                            .status.name,
                      ),
                      const SizedBox(
                          width: 8),
                      _InfoChip(
                        icon: Icons
                            .groups_rounded,
                        label: loc.results,
                        value:
                            '${state.results.length}',
                      ),
                    ],
                  ),
                  if (state.status ==
                      UserSearchStatus
                          .loading) ...[
                    const SizedBox(
                        height: 14),
                    ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  10),
                      child:
                          const LinearProgressIndicator(
                        minHeight: 6,
                      ),
                    ),
                  ],
                  if (state.errorMessage !=
                          null &&
                      state.errorMessage!
                          .isNotEmpty) ...[
                    const SizedBox(
                        height: 12),
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(12),
                      decoration:
                          BoxDecoration(
                        color: isDark
                            ? Colors.red
                                .withOpacity(
                                    0.12)
                            : Colors.red
                                .shade50,
                        borderRadius:
                            BorderRadius
                                .circular(
                                    14),
                        border: Border.all(
                          color: isDark
                              ? Colors.red
                                  .withOpacity(
                                      0.35)
                              : Colors.red
                                  .shade100,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Icon(
                            Icons
                                .error_outline,
                            color: isDark
                                ? Colors.red
                                    .shade300
                                : Colors.red
                                    .shade700,
                            size: 20,
                          ),
                          const SizedBox(
                              width: 8),
                          Expanded(
                            child: Text(
                              state
                                  .errorMessage!,
                              style:
                                  TextStyle(
                                color: isDark
                                    ? Colors
                                        .red
                                        .shade300
                                    : Colors
                                        .red
                                        .shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: state.results.isEmpty
                  ? Center(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 24,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets
                                      .all(18),
                              decoration:
                                  BoxDecoration(
                                color: theme
                                    .colorScheme
                                    .surface,
                                shape: BoxShape
                                    .circle,
                                boxShadow: [
                                  if (!isDark)
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withOpacity(
                                              0.05),
                                      blurRadius:
                                          12,
                                      offset:
                                          const Offset(
                                              0,
                                              4),
                                    ),
                                ],
                              ),
                              child: Icon(
                                isTyping
                                    ? Icons
                                        .search_off_rounded
                                    : Icons
                                        .manage_search_rounded,
                                size: 42,
                                color: theme
                                    .colorScheme
                                    .primary,
                              ),
                            ),
                            const SizedBox(
                                height: 18),
                            Text(
                              isTyping
                                  ? loc
                                      .noPatientsFound
                                  : loc
                                      .startSearchingPatients,
                              style: theme
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color: theme
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                            const SizedBox(
                                height: 8),
                            Text(
                              isTyping
                                  ? loc
                                      .patientNotFoundMessage(
                                      _ctr.text
                                          .trim(),
                                    )
                                  : loc
                                      .searchPatientsInstruction,
                              textAlign:
                                  TextAlign
                                      .center,
                              style: theme
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(
                                        0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        0,
                        16,
                        20,
                      ),
                      itemCount:
                          state.results.length,
                      separatorBuilder:
                          (_, _) =>
                              const SizedBox(
                        height: 12,
                      ),
                      itemBuilder: (_, i) {
                        final u =
                            state.results[i];

                        final username =
                            u.username;

                        final email =
                            u.email;

                        final role =
                            u.role;

                        return Material(
                          color: theme
                              .colorScheme
                              .surface,
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      20),
                          elevation:
                              isDark
                                  ? 0
                                  : 1.5,
                          child: InkWell(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        20),
                            onTap: () =>
                                _showAddPatientDialog(
                              context,
                              username,
                              vm,
                            ),
                            child:
                                Container(
                              decoration:
                                  BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                        20),
                                border:
                                    Border.all(
                                  color: theme
                                      .dividerColor
                                      .withOpacity(
                                          0.15),
                                ),
                              ),
                              padding:
                                  const EdgeInsets
                                      .all(16),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration:
                                        BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                              16),
                                      gradient:
                                          const LinearGradient(
                                        colors: [
                                          Color(
                                              0xFF6EA8FE),
                                          Color(
                                              0xFF4B7BEC),
                                        ],
                                      ),
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .person_rounded,
                                      color: Colors
                                          .white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          14),
                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          username
                                                  .isEmpty
                                              ? loc
                                                  .noUsername
                                              : username,
                                          style: theme
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize:
                                                16,
                                            color: theme
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                        const SizedBox(
                                            height:
                                                6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .email_outlined,
                                              size:
                                                  16,
                                              color: theme
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(
                                                      0.55),
                                            ),
                                            const SizedBox(
                                                width:
                                                    6),
                                            Expanded(
                                              child:
                                                  Text(
                                                email,
                                                style:
                                                    TextStyle(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(
                                                          0.75),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (role !=
                                            null) ...[
                                          const SizedBox(
                                              height:
                                                  10),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal:
                                                  10,
                                              vertical:
                                                  5,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(
                                                      0.12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20),
                                            ),
                                            child:
                                                Text(
                                              role
                                                  .toUpperCase(),
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    11,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: theme
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          8),
                                  Container(
                                    decoration:
                                        BoxDecoration(
                                      color: theme
                                          .scaffoldBackgroundColor,
                                      borderRadius:
                                          BorderRadius.circular(
                                              14),
                                    ),
                                    child:
                                        IconButton(
                                      onPressed:
                                          () =>
                                              _showAddPatientDialog(
                                        context,
                                        username,
                                        vm,
                                      ),
                                      icon:
                                          Icon(
                                        Icons
                                            .person_add_alt_1_rounded,
                                        color: theme
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color:
              theme.scaffoldBackgroundColor,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: theme.dividerColor
                .withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                overflow:
                    TextOverflow.ellipsis,
                text: TextSpan(
                  style:
                      DefaultTextStyle.of(
                              context)
                          .style,
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        color: theme
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: theme
                            .colorScheme
                            .onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}