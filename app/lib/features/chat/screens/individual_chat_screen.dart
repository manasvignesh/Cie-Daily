import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/trusted_backend_client.dart';
import '../data/chat_repository.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';
import '../widgets/shared_post_chat_card.dart';

class IndividualChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String partnerUid;
  final String partnerName;
  final String? partnerPhoto;

  const IndividualChatScreen({
    super.key,
    required this.conversationId,
    required this.partnerUid,
    required this.partnerName,
    this.partnerPhoto,
  });

  @override
  ConsumerState<IndividualChatScreen> createState() =>
      _IndividualChatScreenState();
}

class _IndividualChatScreenState extends ConsumerState<IndividualChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _didInitialScroll = false;
  late String _partnerUid;
  late String _partnerName;
  String? _partnerPhoto;

  @override
  void initState() {
    super.initState();
    _partnerUid = widget.partnerUid;
    _partnerName = widget.partnerName;
    _partnerPhoto = widget.partnerPhoto;
    if (_partnerUid.isEmpty) _hydratePartner();
    // Mark messages as read when opening conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markAsRead(widget.conversationId);
    });
  }

  Future<void> _hydratePartner() async {
    try {
      final partner = await ref
          .read(chatRepositoryProvider)
          .getConversationPartner(widget.conversationId);
      if (!mounted || partner == null) return;
      setState(() {
        _partnerUid = partner['uid'] as String? ?? '';
        _partnerName = partner['name'] as String? ?? 'Student';
        _partnerPhoto = partner['photoUrl'] as String?;
      });
    } catch (_) {
      // The thread itself provides a safe unavailable state when access is lost.
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _partnerUid.isEmpty) return;

    final clientMessageId = TrustedBackendClient.newRequestId();
    _msgController.clear();
    final controller =
        ref.read(chatMessagesProvider(widget.conversationId).notifier);
    controller.addOptimistic(
      clientMessageId: clientMessageId,
      senderId: FirebaseAuth.instance.currentUser!.uid,
      receiverId: _partnerUid,
      content: text,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final receipt = await ref.read(chatRepositoryProvider).sendMessage(
            widget.conversationId,
            _partnerUid,
            text,
            clientMessageId: clientMessageId,
          );
      controller.markAccepted(clientMessageId, messageId: receipt.messageId);
    } catch (_) {
      controller.markFailed(clientMessageId);
    }
  }

  Future<void> _retryMessage(ChatMessageModel message) async {
    final clientMessageId = message.clientMessageId;
    if (clientMessageId == null ||
        message.delivery != ChatMessageDelivery.failed) {
      return;
    }
    final controller =
        ref.read(chatMessagesProvider(widget.conversationId).notifier);
    controller.retry(clientMessageId);
    try {
      final receipt = await ref.read(chatRepositoryProvider).sendMessage(
            widget.conversationId,
            _partnerUid,
            message.content,
            clientMessageId: clientMessageId,
          );
      controller.markAccepted(clientMessageId, messageId: receipt.messageId);
    } catch (_) {
      controller.markFailed(clientMessageId);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadOlder() async {
    final before = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    await ref
        .read(chatMessagesProvider(widget.conversationId).notifier)
        .loadOlder();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final addedExtent = _scrollController.position.maxScrollExtent - before;
      _scrollController.jumpTo(
        (_scrollController.offset + addedExtent)
            .clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    });
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(actionLabel,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppTheme.tertiaryTextColor(context),
                      borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_remove_rounded,
                      color: Colors.amber, size: 20),
                ),
                title: Text('Remove Connection with $_partnerName',
                    style: TextStyle(
                        color: AppTheme.primaryTextColor(context),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await _confirmAction(
                    title: 'Remove connection?',
                    message:
                        'Your conversation with $_partnerName will be removed.',
                    actionLabel: 'Remove',
                  );
                  if (!confirmed || !mounted) return;
                  await ref
                      .read(chatRepositoryProvider)
                      .removeConnection(widget.conversationId);
                  if (mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connection removed')));
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.block_rounded,
                      color: Colors.redAccent, size: 20),
                ),
                title: Text('Block $_partnerName',
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await _confirmAction(
                    title: 'Block $_partnerName?',
                    message:
                        'They will no longer be able to connect or chat with you.',
                    actionLabel: 'Block',
                  );
                  if (!confirmed || !mounted) return;
                  await ref.read(chatRepositoryProvider).blockUser(_partnerUid);
                  await ref
                      .read(chatRepositoryProvider)
                      .removeConnection(widget.conversationId);
                  if (mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Student blocked')));
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevatedColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.primaryTextColor(context), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.surfaceMutedColor(context),
              backgroundImage:
                  _partnerPhoto != null ? NetworkImage(_partnerPhoto!) : null,
              child: _partnerPhoto == null
                  ? Text(
                      _partnerName.isNotEmpty
                          ? _partnerName[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                          color: AppTheme.primaryTextColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 13))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_partnerName,
                      style: TextStyle(
                          color: AppTheme.primaryTextColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('1-to-1 Connection',
                      style: TextStyle(
                          color: AppTheme.secondaryTextColor(context),
                          fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: AppTheme.primaryTextColor(context)),
            onPressed: _showOptionsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── MESSAGE THREAD ─────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              data: (history) {
                final messages = history.messages;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.handshake_outlined,
                            color: AppTheme.tertiaryTextColor(context),
                            size: 48),
                        const SizedBox(height: 12),
                        Text('Connected with $_partnerName',
                            style: TextStyle(
                                color: AppTheme.primaryTextColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Send a message to start chatting!',
                            style: TextStyle(
                                color: AppTheme.secondaryTextColor(context),
                                fontSize: 13)),
                      ],
                    ),
                  );
                }

                if (!_didInitialScroll) {
                  _didInitialScroll = true;
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index == 0) {
                      if (!history.hasMore) return const SizedBox(height: 8);
                      return Center(
                        child: TextButton.icon(
                          onPressed: history.isLoadingOlder ? null : _loadOlder,
                          icon: history.isLoadingOlder
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.history_rounded),
                          label: Text(history.olderLoadFailed
                              ? 'Retry earlier messages'
                              : 'Load earlier messages'),
                        ),
                      );
                    }
                    final msg = messages[index - 1];
                    final isMe = msg.senderId == currentUid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryOrange)),
              error: (e, _) => Center(
                  child: Text("We couldn't load messages. Please try again.",
                      style: TextStyle(
                          color: AppTheme.secondaryTextColor(context)))),
            ),
          ),

          // ── INPUT BOX ──────────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevatedColor(context),
                border: Border(
                    top: BorderSide(color: AppTheme.cardBorderColor(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(
                          color: AppTheme.primaryTextColor(context),
                          fontSize: 15,
                          fontFamily: 'Inter'),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Message $_partnerName...',
                        hintStyle: TextStyle(
                            color: AppTheme.secondaryTextColor(context),
                            fontFamily: 'Inter'),
                        filled: true,
                        fillColor: AppTheme.surfaceMutedColor(context),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: AppTheme.cardBorderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: AppTheme.cardBorderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: Color(0xFFFF5A1F)),
                        ),
                      ),
                      enabled: _partnerUid.isNotEmpty,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'Send message',
                    enabled: _partnerUid.isNotEmpty,
                    child: GestureDetector(
                      onTap: _partnerUid.isEmpty ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A1F),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFFF5A1F)
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
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

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    final sharedData = SharedPostData.tryParse(msg.content);

    return GestureDetector(
      onTap: msg.delivery == ChatMessageDelivery.failed
          ? () => _retryMessage(msg)
          : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (sharedData != null)
              SharedPostChatCard(data: sharedData, isMe: isMe)
            else
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppTheme.primaryOrange.withValues(alpha: 0.12)
                      : AppTheme.cardColor(context),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  border: Border.all(
                    color: isMe
                        ? AppTheme.primaryOrange.withValues(alpha: 0.28)
                        : AppTheme.cardBorderColor(context),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontSize: 15,
                      height: 1.4,
                      fontFamily: 'Inter'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
              child: Text(
                msg.delivery == ChatMessageDelivery.sending
                    ? 'Sending…'
                    : msg.delivery == ChatMessageDelivery.failed
                        ? 'Not sent · Tap to retry'
                        : _formatMsgTime(msg.timestamp),
                style: TextStyle(
                    color: msg.delivery == ChatMessageDelivery.failed
                        ? Colors.redAccent
                        : AppTheme.tertiaryTextColor(context),
                    fontSize: 11,
                    fontFamily: 'Inter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMsgTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}
