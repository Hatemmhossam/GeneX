class ChatMessageModel {
  final int id;
  final int conversation;
  final int senderId;
  final String senderUsername;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String? attachmentName;
  final String? attachmentUrl;

  ChatMessageModel({
    required this.id,
    required this.conversation,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.attachmentName,
    this.attachmentUrl,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      conversation: json['conversation'] is int
          ? json['conversation']
          : int.parse(json['conversation'].toString()),
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.parse(json['sender_id'].toString()),
      senderUsername: json['sender_username']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      attachmentName: json['attachment_name']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
    );
  }
}