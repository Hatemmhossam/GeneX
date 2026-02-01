import '../services/api_service.dart'; // Make sure this import is correct
import '../models/user_model.dart';

class UserRepository {
  // 1. Declare the variable
  final ApiService _apiService; 

  // 2. Initialize it in the constructor
  UserRepository(this._apiService);

  // --- Methods ---

  /// Bridges the ViewModel to the ApiService
  Future<List<UserModel>> searchPatients(String query) async {
    // 3. Now '_apiService' is defined and valid
    return _apiService.searchPatients(query);
  }

  // ... keep your other existing methods here like 'searchUsersByUsername' ...
  Future<List<UserModel>> searchUsersByUsername(String username) async {
    return _apiService.searchUsersByUsername(username);
  }

  Future<bool> addPatient(String patientUsername) async {
    return _apiService.addPatient(patientUsername);
  }
} 