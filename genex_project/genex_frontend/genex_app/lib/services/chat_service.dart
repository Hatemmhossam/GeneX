import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/assigned_doctor_model.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import 'package:file_picker/file_picker.dart';

class ChatService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String wsBaseUrl = 'ws://127.0.0.1:8000';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<AssignedDoctorModel>> getAssignedDoctors() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patient/assigned-doctors/'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load assigned doctors: ${response.body}');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => AssignedDoctorModel.fromJson(e)).toList();
  }

  Future<ConversationModel> openConversation({
    required int doctorId,
    required int patientId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/open/'),
      headers: await _headers(),
      body: jsonEncode({
        'doctor_id': doctorId,
        'patient_id': patientId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to open conversation: ${response.body}');
    }

    return ConversationModel.fromJson(jsonDecode(response.body));
  }

  Future<List<ChatMessageModel>> getMessages(int conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages/'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load messages: ${response.body}');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => ChatMessageModel.fromJson(e)).toList();
  }

  Future<void> markMessagesAsRead(int conversationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId/read/'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark messages as read: ${response.body}');
    }
  }

  Future<String> buildWebSocketUrl(int conversationId) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found');
    }

    return '$wsBaseUrl/ws/chat/$conversationId/?token=$token';
  }

  // ================= FILE UPLOAD =================
Future<ChatMessageModel> uploadAttachment({
  required int conversationId,
  required PlatformFile file,
  String? content,
}) async {
  final token = await _getToken();

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/api/chat/conversations/$conversationId/upload/'),
  );

  request.headers['Authorization'] = 'Bearer $token';

  // Attach file
  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      file.bytes!,
      filename: file.name,
    ),
  );

  // Optional text message
  if (content != null && content.isNotEmpty) {
    request.fields['content'] = content;
  }

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

if (response.statusCode != 200 &&
    response.statusCode != 201) {
  throw Exception('Upload failed: $responseBody');
}

  return ChatMessageModel.fromJson(jsonDecode(responseBody));
}

Future<void> requestReportPermission({
    required int reportId,
    required int doctorId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/request-report-permission/'),
      headers: await _headers(),
      body: jsonEncode({
        'report_id': reportId,
        'doctor_id': doctorId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to request permission: ${response.body}');
    }
  }

Future<void> approveReportPermission({
  required int reportId,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/approve-report-permission/'),
    headers: await _headers(),
    body: jsonEncode({
      'report_id': reportId,
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to approve permission: ${response.body}');
  }
}
Future<List<dynamic>> getPendingReportPermissions() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/pending-report-permissions/'),
    headers: await _headers(),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load pending permissions: ${response.body}');
  }

  return jsonDecode(response.body) as List<dynamic>;
}



}


