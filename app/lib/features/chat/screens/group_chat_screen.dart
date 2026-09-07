import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/group_chat_repository.dart';
import '../models/group_chat_model.dart';
import '../providers/group_chat_providers.dart';
import '../utils/shared_content_formatter.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgController.clear();
    setState(() => _isSending = true);

    try {
      await ref
          .read(groupChatRepositoryProvider)
          .sendGroupMessage(widget.groupId, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("We couldn't send that message. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
    await ref.read(groupMessagesProvider(widget.groupId).notifier).loadOlder();
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

  void _showGroupInfoSheet(GroupChatModel group) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: AppTheme.tertiaryTextColor(context),
                        borderRadius: BorderRadius.circular(2))),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppTheme.primaryOrange.withValues(alpha: 0.2),
                    child: Text(
                        group.name.isNotEmpty
                            ? group.name[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name,
                            style: TextStyle(
                                color: AppTheme.primaryTextColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'Outfit')),
                        const SizedBox(height: 4),
                        Text(
                            '${group.category} · ${group.members.length} members',
                            style: TextStyle(
                                color: AppTheme.secondaryTextColor(context),
                                fontSize: 13,
                                fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                ],
              ),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('About Community',
                    style: TextStyle(
                        color: AppTheme.secondaryTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(group.description,
                    style: TextStyle(
                        color: AppTheme.primaryTextColor(context),
                        fontSize: 14,
                        fontFamily: 'Inter')),
              ],
              const SizedBox(height: 20),
              Text('Members',
                  style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  children: group.memberDetails.entries.map((entry) {
                    final details =
                        Map<String, dynamic>.from(entry.value as Map? ?? {});
                    final name = details['name'] as String? ?? 'Student';
                    final photo = details['photoUrl'] as String?;
                    final role = details['role'] as String? ?? 'member';

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.surfaceMutedColor(context),
                        backgroundImage:
                            photo != null ? NetworkImage(photo) : null,
                        child: photo == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                style: TextStyle(
                                    color: AppTheme.primaryTextColor(context),
                                    fontSize: 12))
                            : null,
                      ),
                      title: Text(name,
                          style: TextStyle(
                              color: AppTheme.primaryTextColor(context),
                              fontWeight: FontWeight.w600)),
                      trailing: role == 'admin'
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Text('Admin',
                                  style: TextStyle(
                                      color: AppTheme.primaryOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: AppTheme.cardColor(dCtx),
                      title: Text('Leave Community?',
                          style: TextStyle(
                              color: AppTheme.primaryTextColor(dCtx))),
                      content: Text(
                          'Are you sure you want to leave "${group.name}"?',
                          style: TextStyle(
                              color: AppTheme.secondaryTextColor(dCtx))),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: const Text('Leave',
                                style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );

                  if (confirm == true && mounted && ctx.mounted) {
                    Navigator.pop(ctx);
                    await ref
                        .read(groupChatRepositoryProvider)
                        .leaveGroup(group.id);
                    if (mounted && context.mounted) {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Left "${group.name}"')));
                    }
                  }
                },
                icon: const Icon(Icons.exit_to_app_rounded,
                    color: Colors.redAccent),
                label: const Text('Leave Community',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));
    final userGroupsAsync = ref.watch(userGroupsProvider);

    GroupChatModel? currentGroup;
    userGroupsAsync.whenData((groups) {
      final matches = groups.where((g) => g.id == widget.groupId);
      if (matches.isNotEmpty) currentGroup = matches.first;
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevatedColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.primaryTextColor(context)),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () {
            if (currentGroup != null) _showGroupInfoSheet(currentGroup!);
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
                child: Text(
                  currentGroup?.name.isNotEmpty == true
                      ? currentGroup!.name[0].toUpperCase()
                      : 'G',
                  style: const TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentGroup?.name ?? 'Community Chat',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTextColor(context),
                          fontFamily: 'Outfit'),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentGroup != null)
                      Text(
                        '${currentGroup!.members.length} members · ${currentGroup!.category}',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondaryTextColor(context),
                            fontFamily: 'Inter'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded,
                color: AppTheme.secondaryTextColor(context)),
            onPressed: () {
              if (currentGroup != null) _showGroupInfoSheet(currentGroup!);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (history) {
                final messages = history.messages;
                if (messages.isEmpty) {
                  return Center(
                    child: Text('No messages yet. Say hi to the community!',
                        style: TextStyle(
                            color: AppTheme.secondaryTextColor(context))),
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                    if (msg.isSystemMessage) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceMutedColor(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sharedContentPreview(msg.content),
                            style: TextStyle(
                                color: AppTheme.secondaryTextColor(context),
                                fontSize: 12,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }

                    final isMe = msg.senderId == (user?.uid ?? '');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  AppTheme.surfaceMutedColor(context),
                              backgroundImage: msg.senderPhotoUrl != null
                                  ? NetworkImage(msg.senderPhotoUrl!)
                                  : null,
                              child: msg.senderPhotoUrl == null
                                  ? Text(
                                      msg.senderName.isNotEmpty
                                          ? msg.senderName[0].toUpperCase()
                                          : 'S',
                                      style: TextStyle(
                                          color: AppTheme.primaryTextColor(
                                              context),
                                          fontSize: 10))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, bottom: 2),
                                    child: Text(msg.senderName,
                                        style: TextStyle(
                                            color: AppTheme.secondaryTextColor(
                                                context),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppTheme.primaryOrange
                                        : AppTheme.cardColor(context),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(isMe ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(isMe ? 4 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    sharedContentPreview(msg.content),
                                    style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : AppTheme.primaryTextColor(
                                                context),
                                        fontSize: 14,
                                        fontFamily: 'Inter'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
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

          // Composer
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                          fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Message community...',
                        hintStyle: TextStyle(
                            color: AppTheme.secondaryTextColor(context)),
                        filled: true,
                        fillColor: AppTheme.surfaceMutedColor(context),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryOrange, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: AppTheme.primaryOrange),
                    onPressed: _sendMessage,
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
