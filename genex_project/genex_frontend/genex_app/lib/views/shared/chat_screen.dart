import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/chat_message_model.dart';
import '../../viewmodels/providers.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _channel;
  List<ChatMessageModel> messages = [];

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

      final oldMessages = await chatService.getMessages(widget.conversationId);
      await chatService.markMessagesAsRead(widget.conversationId);
      final wsUrl = await chatService.buildWebSocketUrl(widget.conversationId);

      if (!mounted) return;

      setState(() {
        // ListView is reversed, so the newest message should be at index 0.
        messages = oldMessages.reversed.toList();
        isLoading = false;
      });

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data);
          final message = ChatMessageModel.fromJson(decoded);
          final isMine = message.senderId.toString() == currentUserId;

          if (!mounted) return;

          setState(() {
            final alreadyExists = messages.any((m) => m.id == message.id);
            if (!alreadyExists) {
              messages.add(message);
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
        messages = oldMessages;
        isLoading = false;
      });
    }
  }

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
    _scrollToBottom();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
    if (index == messages.length - 1) return true;

    final current = messages[index].createdAt;
    final older = messages[index + 1].createdAt;

    return current.year != older.year ||
        current.month != older.month ||
        current.day != older.day;
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
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: const TextStyle(fontSize: 15),
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
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: theme.colorScheme.primary,
              size: 46,
            ),
            const SizedBox(height: 14),
            Text(
              loc.noMessagesYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a secure medical conversation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.60),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildInputBar() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(0.12),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.24 : 0.06,
              ),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: isSendingAttachment ? null : _pickAndUploadFile,
              tooltip: loc.uploadFile,
              icon: isSendingAttachment
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.attach_file_rounded,
                      color: theme.colorScheme.primary,
                    ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: loc.typeMessage,
                  prefixIcon: Icon(
                    Icons.message_outlined,
                    color: theme.colorScheme.primary.withOpacity(0.75),
                  ),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.045)
                      : theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red : theme.colorScheme.secondary,
              ),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    _channel?.sink.close();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.receiverName),
      ),
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
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.all(12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                    _buildInputBar(),
                  ],
                ),
    );
  }
}