// lib/viewmodels/user_search_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import 'user_search_state.dart';

class UserSearchViewModel extends StateNotifier<UserSearchState> {
  final UserRepository repo;

  UserSearchViewModel(this.repo) : super(UserSearchState.idle());

  Future<void> search(String username) async {
    final q = username.trim();
    
    // 1. If query is empty, clear everything immediately
    if (q.isEmpty) {
      clear();
      return;
    }

    // 2. Set loading, but clear any previous error messages
    state = state.copyWith(status: UserSearchStatus.loading, errorMessage: null);

    try {
      // 3. ✅ Call the specific 'searchPatients' method.
      // We use this instead of generic 'searchUsers' to ensure we only get patients.
      final results = await repo.searchPatients(q);
      
      state = state.copyWith(
        status: UserSearchStatus.success,
        results: results,
      );
    } catch (e) {
      // 4. Clean up the error message (removes "Exception: " prefix if present)
      final cleanError = e.toString().replaceAll('Exception:', '').trim();
      
      state = state.copyWith(
        status: UserSearchStatus.error,
        errorMessage: cleanError,
      );
    }
  }
// Add this method to your existing UserSearchViewModel class
  Future<bool> sendAddRequest(String patientUsername) async {
    try {
      final success = await repo.addPatient(patientUsername);
      return success;
    } catch (e) {
      return false;
    }
  }
  void clear() {
    state = UserSearchState.idle();
  }
}