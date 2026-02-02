import '../models/user_model.dart';

enum UserSearchStatus { idle, loading, success, error }

class UserSearchState {
  final UserSearchStatus status;
  final List<UserModel> results;
  final String? errorMessage;

  const UserSearchState({
    required this.status,
    required this.results,
    this.errorMessage,
  });

  factory UserSearchState.idle() =>
      const UserSearchState(status: UserSearchStatus.idle, results: []);

  UserSearchState copyWith({
    UserSearchStatus? status,
    List<UserModel>? results,
    String? errorMessage,
  }) {
    return UserSearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: errorMessage,
    );
  }
}