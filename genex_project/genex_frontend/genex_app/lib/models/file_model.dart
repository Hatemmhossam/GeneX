// lib/models/file_model.dart
class FileModel {
  final String fileName;
  final String fileUrl;
  final String uploadedAt;  // Add uploadedAt field


  FileModel({
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,  // Include uploadedAt in constructor

  });

  // Factory method to create FileModel from JSON
  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      fileName: json['file_name'],
      fileUrl: json['file_url'],
      uploadedAt: json['uploaded_at'],  // Extract uploadedAt from JSON

    );
  }

  // Method to convert FileModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'file_url': fileUrl,
      'uploaded_at': uploadedAt,  // Include uploadedAt when converting to JSON

    };
  }
}
