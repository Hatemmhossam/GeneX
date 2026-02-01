import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/user_search_state.dart';
import '../../models/user_model.dart';

class UserSearchView extends ConsumerStatefulWidget {
  const UserSearchView({super.key});

  @override
  ConsumerState<UserSearchView> createState() => _UserSearchViewState();
}

class _UserSearchViewState extends ConsumerState<UserSearchView> {
  final _ctr = TextEditingController();
  Timer? _debounce;

  // Set to true to avoid hitting the API on every single keystroke
  final bool _useDebounce = true;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctr.dispose();
    super.dispose();
  }

  void _triggerSearch(String value) {
    // This calls the ViewModel. The ViewModel determines WHICH API to call.
    ref.read(userSearchViewModelProvider.notifier).search(value);
  }

  void _onChanged(String value) {
    if (!_useDebounce) {
      _triggerSearch(value);
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _triggerSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSearchViewModelProvider);
    final vm = ref.read(userSearchViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Patients')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctr,
              onChanged: (v) {
                setState(() {});
                _onChanged(v);
              },
              decoration: InputDecoration(
                labelText: 'Search by patient username',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _ctr.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctr.clear();
                          _debounce?.cancel();
                          vm.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Query: "${_ctr.text}" • Status: ${state.status.name} • Results: ${state.results.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            if (state.status == UserSearchStatus.loading)
              const LinearProgressIndicator(),

            const SizedBox(height: 12),

            Expanded(
              child: state.results.isEmpty
                  ? Center(
                      child: Text(
                        _ctr.text.trim().isEmpty
                            ? 'Type to search for patients...'
                            : 'No patients found for "${_ctr.text.trim()}"',
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = state.results[i];

                        final username = u.username;
                        final email = u.email;
                        final role = u.role;

                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            username.isEmpty ? '(no username)' : username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(email),
                              if (role != null)
                                Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.blueGrey),
                                ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Add Patient?'),
                                content: Text(
                                    'Do you want to send a add request to $username?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx); // Close dialog

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Sending request...')),
                                      );

                                      // Call the method we added in the previous step
                                      final success =
                                          await vm.sendAddRequest(username);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                        if (success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Request sent to $username!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Failed. Request might already exist.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            );
                          },
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