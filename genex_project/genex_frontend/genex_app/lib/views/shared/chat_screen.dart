import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:genex_app/l10n/app_localizations.dart';

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
  ConsumerState<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends ConsumerState<ChatScreen> {
  final TextEditingController
      _messageController =
      TextEditingController();

  final ScrollController
      _scrollController =
      ScrollController();

  WebSocketChannel? _channel;

  List<ChatMessageModel>
      messages = [];

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

  bool get _isDoctor =>
      currentUserRole
              ?.toLowerCase() ==
          'doctor';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final loc =
        AppLocalizations.of(context)!;

    try {
      final authState = ref.read(
        authViewModelProvider,
      );

      currentUserId =
          authState.user?.id
              ?.toString();

      currentUserRole =
          authState.user?.role
              ?.toString();

      final chatService = ref.read(
        chatServiceProvider,
      );

      final oldMessages =
          await chatService
              .getMessages(
        widget.conversationId,
      );

      await chatService
          .markMessagesAsRead(
        widget.conversationId,
      );

      final wsUrl =
          await chatService
              .buildWebSocketUrl(
        widget.conversationId,
      );

      _channel =
          WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      _channel!.stream.listen(
        (data) {
          final decoded =
              jsonDecode(data);

          final message =
              ChatMessageModel
                  .fromJson(
            decoded,
          );

          final isMine =
              message.senderId
                      .toString() ==
                  currentUserId;

          if (!mounted) return;

          setState(() {
            final alreadyExists =
                messages.any(
              (m) =>
                  m.id ==
                  message.id,
            );

            if (!alreadyExists) {
              messages.add(
                message,
              );
            }
          });

          if (!isMine) {
            ScaffoldMessenger.of(
                    context)
                .showSnackBar(
              SnackBar(
                content: Text(
                  '${message.senderUsername}: ${message.content}',
                ),
                duration:
                    const Duration(
                  seconds: 2,
                ),
                behavior:
                    SnackBarBehavior
                        .floating,
              ),
            );
          }

          _scrollToBottom();
        },
        onError: (e) {
          if (!mounted) return;

          setState(() {
            error =
                '${loc.websocketError}: $e';
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
    final text =
        _messageController.text
            .trim();

    if (text.isEmpty ||
        _channel == null) {
      return;
    }

    _channel!.sink.add(
      jsonEncode({
        'content': text,
      }),
    );

    _messageController.clear();
  }

  Future<void>
      _pickAndUploadFile() async {
    final loc =
        AppLocalizations.of(context)!;

    try {
      final result =
          await FilePicker.platform
              .pickFiles(
        withData: true,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final file =
          result.files.first;

      final chatService =
          ref.read(
        chatServiceProvider,
      );

      final uploadedMessage =
          await chatService
              .uploadAttachment(
        conversationId:
            widget.conversationId,
        file: file,
        content:
            _messageController.text
                .trim(),
      );

      if (!mounted) return;

      setState(() {
        final alreadyExists =
            messages.any(
          (m) =>
              m.id ==
              uploadedMessage.id,
        );

        if (!alreadyExists) {
          messages.add(
            uploadedMessage,
          );
        }
      });

      _messageController.clear();

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${loc.fileUploadFailed}: $e',
          ),
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (_scrollController
            .hasClients) {
          _scrollController
              .animateTo(
            _scrollController
                    .position
                    .maxScrollExtent +
                80,
            duration:
                const Duration(
              milliseconds: 250,
            ),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  String _formatTime(
    DateTime dt,
  ) {
    final hour =
        dt.hour % 12 == 0
            ? 12
            : dt.hour % 12;

    final minute = dt.minute
        .toString()
        .padLeft(2, '0');

    final suffix =
        dt.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $suffix';
  }

  String _formatDateLabel(
    DateTime dt,
  ) {
    final loc =
        AppLocalizations.of(context)!;

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final date = DateTime(
      dt.year,
      dt.month,
      dt.day,
    );

    final diff =
        today
            .difference(date)
            .inDays;

    if (diff == 0) {
      return loc.today;
    }

    if (diff == 1) {
      return loc.yesterday;
    }

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  bool _shouldShowDateHeader(
    int index,
  ) {
    if (index == 0) {
      return true;
    }

    final current =
        messages[index]
            .createdAt;

    final previous =
        messages[index - 1]
            .createdAt;

    return current.year !=
            previous.year ||
        current.month !=
            previous.month ||
        current.day !=
            previous.day;
  }

  Widget _buildDateHeader(
    ChatMessageModel message,
  ) {
    final theme =
        Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surface,
            borderRadius:
                BorderRadius.circular(
                    14),
            border: Border.all(
              color: theme
                  .dividerColor
                  .withOpacity(0.2),
            ),
          ),
          child: Text(
            _formatDateLabel(
              message.createdAt,
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color: theme
                  .colorScheme
                  .onSurface
                  .withOpacity(0.65),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessageModel message,
  ) {
    final theme =
        Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    final isMine =
        message.senderId
                .toString() ==
            currentUserId;

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.symmetric(
          vertical: 4,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.75,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? theme.colorScheme
                  .primary
              : theme
                  .colorScheme.surface,
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(
                    16),
            topRight:
                const Radius.circular(
                    16),
            bottomLeft:
                Radius.circular(
              isMine ? 16 : 4,
            ),
            bottomRight:
                Radius.circular(
              isMine ? 4 : 16,
            ),
          ),
          border: Border.all(
            color: isMine
                ? theme.colorScheme
                    .primary
                : theme.dividerColor
                    .withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine
                  ? CrossAxisAlignment
                      .end
                  : CrossAxisAlignment
                      .start,
          children: [
            if (message
                .content
                .isNotEmpty)
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isMine
                      ? Colors.white
                      : theme
                          .colorScheme
                          .onSurface,
                ),
              ),

            if (message
                    .attachmentUrl !=
                null) ...[
              if (message
                  .content
                  .isNotEmpty)
                const SizedBox(
                    height: 8),

              Container(
                padding:
                    const EdgeInsets.all(
                        10),
                decoration:
                    BoxDecoration(
                  color: isMine
                      ? Colors.white
                          .withOpacity(
                              0.15)
                      : theme
                          .scaffoldBackgroundColor,
                  borderRadius:
                      BorderRadius.circular(
                          10),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .insert_drive_file_outlined,
                      size: 18,
                      color: isMine
                          ? Colors.white
                          : theme
                              .colorScheme
                              .onSurface,
                    ),

                    const SizedBox(
                        width: 6),

                    Flexible(
                      child: Text(
                        message.attachmentName ??
                            loc.attachment,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            TextStyle(
                          color: isMine
                              ? Colors
                                  .white
                              : theme
                                  .colorScheme
                                  .onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(
                height: 6),

            Text(
              _formatTime(
                message.createdAt,
              ),
              style: TextStyle(
                fontSize: 11,
                color: isMine
                    ? Colors.white70
                    : theme
                        .colorScheme
                        .onSurface
                        .withOpacity(
                            0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChips() {
    final theme =
        Theme.of(context);

    if (!_isDoctor) {
      return const SizedBox
          .shrink();
    }

    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            quickReplies.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 8,
        ),
        itemBuilder:
            (context, index) {
          final reply =
              quickReplies[index];

          return ActionChip(
            backgroundColor:
                theme
                    .colorScheme
                    .surface,
            side: BorderSide(
              color: theme
                  .dividerColor
                  .withOpacity(0.2),
            ),
            avatar: Icon(
              Icons.bolt_outlined,
              size: 18,
              color: theme
                  .colorScheme
                  .primary,
            ),
            label: Text(
              reply,
              style: TextStyle(
                color: theme
                    .colorScheme
                    .onSurface,
              ),
            ),
            onPressed: () {
              _messageController
                  .text = reply;

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
    _scrollController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.receiverName,
          style: TextStyle(
            color:
                theme.colorScheme
                    .onSurface,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator(
                color: theme
                    .colorScheme
                    .primary,
              ),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(20),
                    child: Text(
                      error!,
                      textAlign:
                          TextAlign
                              .center,
                      style:
                          const TextStyle(
                        color:
                            Colors.red,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child:
                          messages.isEmpty
                              ? Center(
                                  child:
                                      Text(
                                    loc
                                        .noMessagesYet,
                                    style:
                                        TextStyle(
                                      color: theme
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(
                                              0.6),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller:
                                      _scrollController,
                                  padding:
                                      const EdgeInsets.all(
                                    12,
                                  ),
                                  itemCount:
                                      messages.length,
                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    final message =
                                        messages[
                                            index];

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .stretch,
                                      children: [
                                        if (_shouldShowDateHeader(
                                          index,
                                        ))
                                          _buildDateHeader(
                                            message,
                                          ),
                                        _buildMessageBubble(
                                          message,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                    ),

                    _buildQuickReplyChips(),

                    SafeArea(
                      top: false,
                      child: Container(
                        color: theme
                            .colorScheme
                            .surface,
                        padding:
                            const EdgeInsets.fromLTRB(
                          12,
                          8,
                          12,
                          12,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed:
                                  _pickAndUploadFile,
                              icon: Icon(
                                Icons
                                    .attach_file,
                                color: theme
                                    .colorScheme
                                    .primary,
                              ),
                              tooltip:
                                  loc.uploadFile,
                            ),

                            Expanded(
                              child:
                                  TextField(
                                controller:
                                    _messageController,
                                minLines: 1,
                                maxLines: 4,
                                style:
                                    TextStyle(
                                  color: theme
                                      .colorScheme
                                      .onSurface,
                                ),
                                decoration:
                                    InputDecoration(
                                  hintText:
                                      loc.typeMessage,
                                  hintStyle:
                                      TextStyle(
                                    color: theme
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(
                                            0.5),
                                  ),
                                  filled:
                                      true,
                                  fillColor:
                                      theme
                                          .inputDecorationTheme
                                          .fillColor,
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                    borderSide:
                                        BorderSide.none,
                                  ),
                                ),
                                onSubmitted:
                                    (_) =>
                                        _sendMessage(),
                              ),
                            ),

                            const SizedBox(
                                width: 8),

                            CircleAvatar(
                              backgroundColor:
                                  theme
                                      .colorScheme
                                      .primary,
                              child:
                                  IconButton(
                                onPressed:
                                    _sendMessage,
                                icon:
                                    const Icon(
                                  Icons.send,
                                  color: Colors
                                      .white,
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