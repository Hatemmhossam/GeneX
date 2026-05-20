import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/chat_message_model.dart';
import '../../viewmodels/providers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String receiverName;
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;

            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
          });
        },
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    setState(() {
      _isListening = false;
    });
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;

    await _flutterTts.stop();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _channel;
  List<ChatMessageModel> messages = [];
  StreamSubscription? _subscription;

  bool isLoading = true;
  String? error;
  String? currentUserId;
  String? currentUserRole;

  final List<String> quickReplies = [
    'Please upload your latest report.',
    'Please schedule a follow-up appointment.',
    'Your results need review.',
    'Please repeat this test and send the result.',
    'Please monitor your symptoms and update me tomorrow.',
  ];

  bool get _isDoctor => currentUserRole?.toLowerCase() == 'doctor';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final authState = ref.read(authViewModelProvider);
      currentUserId = authState.user?.id?.toString();
      currentUserRole = authState.user?.role?.toString();

      final chatService = ref.read(chatServiceProvider);

      final oldMessages = await chatService
          .getMessages(widget.conversationId)
          .timeout(const Duration(seconds: 8));
      await chatService.markMessagesAsRead(widget.conversationId);
      final wsUrl = await chatService.buildWebSocketUrl(widget.conversationId);

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _subscription = _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data);
          final message = ChatMessageModel.fromJson(decoded);
          final isMine = message.senderId.toString() == currentUserId;

          if (!mounted) return;

          setState(() {
            final alreadyExists = messages.any((m) => m.id == message.id);
            if (!alreadyExists) {
              messages.insert(0, message);
            }
          });

          if (!isMine) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${message.senderUsername}: ${message.content}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          _scrollToBottom();
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            error = 'WebSocket error: $e';
          });
        },
      );

      if (!mounted) return;

      setState(() {
        messages = oldMessages.reversed.toList();
        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _channel == null) return;

    _channel!.sink.add(jsonEncode({'content': text}));
    _messageController.clear();
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final chatService = ref.read(chatServiceProvider);

      final uploadedMessage = await chatService.uploadAttachment(
        conversationId: widget.conversationId,
        file: file,
        content: _messageController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        final alreadyExists = messages.any((m) => m.id == uploadedMessage.id);
        if (!alreadyExists) {
          messages.add(uploadedMessage);
        }
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File upload failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.jumpTo(0);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;

    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;

    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  Widget _buildDateHeader(ChatMessageModel message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _formatDateLabel(message.createdAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isMine = message.senderId.toString() == currentUserId;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      message.content,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _speak(message.content),
                    child: const Icon(Icons.volume_up_outlined, size: 18),
                  ),
                ],
              ),
            if (message.attachmentUrl != null) ...[
              if (message.content.isNotEmpty) const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message.attachmentName ?? 'Attachment',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChips() {
    if (!_isDoctor) return const SizedBox.shrink();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = quickReplies[index];

          return ActionChip(
            avatar: const Icon(Icons.bolt_outlined, size: 18),
            label: Text(reply),
            onPressed: () {
              _messageController.text = reply;
              _sendMessage();
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subscription?.cancel();
    _scrollController.dispose();
    _channel?.sink.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(title: Text(widget.receiverName)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet. Start the conversation.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_shouldShowDateHeader(index))
                                  _buildDateHeader(message),
                                _buildMessageBubble(message),
                              ],
                            );
                          },
                        ),
                ),
                _buildQuickReplyChips(),
                SafeArea(
                  top: false,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _pickAndUploadFile,
                          icon: const Icon(Icons.attach_file),
                          tooltip: 'Upload File',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),

                        CircleAvatar(
                          backgroundColor: _isListening
                              ? Colors.red
                              : Theme.of(context).colorScheme.secondary,
                          child: IconButton(
                            onPressed: () {
                              if (_isListening) {
                                _stopListening();
                              } else {
                                _startListening();
                              }
                            },
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
