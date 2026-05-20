
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:genex_app/l10n/app_localizations.dart';

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
  bool isSendingAttachment = false;

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

    final oldMessages = await chatService
        .getMessages(widget.conversationId)
        .timeout(const Duration(seconds: 12));

    await chatService
        .markMessagesAsRead(widget.conversationId)
        .timeout(const Duration(seconds: 12));


      setState(() {
        messages = oldMessages.reversed.toList();
        isLoading = false;
      });

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data);
        final message = ChatMessageModel.fromJson(decoded);

        if (!mounted) return;

        setState(() {
          final alreadyExists = messages.any((m) => m.id == message.id);
          if (!alreadyExists) messages.add(message);
        });

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
    final loc = AppLocalizations.of(context)!;

    try {
      final result = await FilePicker.platform.pickFiles(withData: true);

      if (result == null || result.files.isEmpty) return;

      setState(() => isSendingAttachment = true);

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
        if (!alreadyExists) messages.add(uploadedMessage);
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.fileUploadFailed}: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isSendingAttachment = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 90,
          duration: const Duration(milliseconds: 260),
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
    final loc = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return loc.today;
    if (diff == 1) return loc.yesterday;

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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  theme.brightness == Brightness.dark ? 0.18 : 0.04,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            _formatDateLabel(message.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withOpacity(0.62),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final isMine = message.senderId.toString() == currentUserId;
    final maxWidth = MediaQuery.of(context).size.width > 700
        ? 480.0
        : MediaQuery.of(context).size.width * 0.76;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          gradient: isMine
    ? LinearGradient(
        colors: [
          theme.colorScheme.primary,
          const Color(0xFF2563EB),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )
    : null,
          color: isMine ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 6),
            bottomRight: Radius.circular(isMine ? 6 : 20),
          ),
          border: Border.all(
            color: isMine
                ? Colors.transparent
                : theme.dividerColor.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.18 : 0.05,
              ),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
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
              if (message.content.isNotEmpty) const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isMine
                      ? Colors.white.withOpacity(0.16)
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isMine
                        ? Colors.white.withOpacity(0.18)
                        : theme.dividerColor.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 20,
                      color: isMine ? Colors.white : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message.attachmentName ?? loc.attachment,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isMine
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 7),
            Text(
              _formatTime(message.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isMine
                    ? Colors.white70
                    : theme.colorScheme.onSurface.withOpacity(0.48),
              ),

            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.08);
  }

  Widget _buildQuickReplyChips() {
    if (!_isDoctor) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = quickReplies[index];

          return ActionChip(
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(
              color: theme.dividerColor.withOpacity(0.14),
            ),
            avatar: Icon(
              Icons.bolt_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              reply,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
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
            const SizedBox(width: 10),
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
    _subscription?.cancel();
    _scrollController.dispose();
    _channel?.sink.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(

      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              child: Icon(
                Icons.medical_services_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.receiverName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
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
