import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/breakpoint_logo.dart';
import '../../../core/theme/responsive.dart';
import '../../profile/providers/profile_provider.dart';
import '../../user/data/firebase_user_repository.dart';
import '../data/chat_repository.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';
import '../providers/group_chat_providers.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/explore_groups_sheet.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  int _selectedTabIndex = 0; // 0: Direct Messages, 1: Interest Groups

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showAddConnectionSheet() {
    _codeController.clear();
    final cardColor = AppTheme.cardColor(context);
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final inputFill = AppTheme.inputFillColor(context);
    final borderColor = AppTheme.cardBorderColor(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                      color: secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                'Add Connection',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                    fontFamily: 'Outfit'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Enter a student\'s Connection Code to start a direct message channel.',
                style: TextStyle(
                    fontSize: 13, color: secondaryText, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'e.g. MANAS-7K4P2',
                  hintStyle: TextStyle(
                      color: secondaryText.withValues(alpha: 0.5),
                      letterSpacing: 0,
                      fontSize: 15),
                  filled: true,
                  fillColor: inputFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryOrange, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final code = _codeController.text.trim();
                        if (code.isEmpty) return;

                        setStateSheet(() => _isSubmitting = true);
                        try {
                          final msg = await ref
                              .read(chatRepositoryProvider)
                              .sendConnectionRequest(code);
                          if (mounted && ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(msg),
                                  backgroundColor: Colors.green),
                            );
                          }
                        } on ConnectionCodeException catch (error) {
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(error.message),
                                  backgroundColor: Colors.redAccent),
                            );
                          }
                        } catch (_) {
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Couldn't connect right now. Try again."),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } finally {
                          if (mounted && ctx.mounted) {
                            setStateSheet(() => _isSubmitting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Send Request',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.cardColor(context),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const CreateGroupSheet(),
    );
  }

  void _showExploreGroupsSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.cardColor(context),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const ExploreGroupsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    final connectionCodeAsync = ref.watch(connectionCodeProvider);
    final pendingReqsAsync = ref.watch(pendingRequestsProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final userGroupsAsync = ref.watch(userGroupsProvider);

    final profileCode =
        userProfileAsync.value?['connectionCode']?.toString().trim() ?? '';
    final connectionCode = connectionCodeAsync.valueOrNull ?? profileCode;
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final inputFill = AppTheme.inputFillColor(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, AppResponsive.overlayBottomOffset(context) + 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Connect',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: primaryText,
                              fontFamily: 'Outfit',
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const BreakpointDotMarker(size: 8),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Conversations that feel close',
                        style: TextStyle(
                          fontSize: 15,
                          color: secondaryText,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  if (_selectedTabIndex == 0)
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded,
                          color: AppTheme.primaryOrange, size: 22),
                      onPressed: _showAddConnectionSheet,
                      tooltip: 'Add Person',
                    )
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.explore_outlined,
                          color: AppTheme.primaryOrange, size: 22),
                      onPressed: _showExploreGroupsSheet,
                      tooltip: 'Discover',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── COMPACT CONNECTION CODE ROW ──────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_rounded,
                        color: AppTheme.primaryOrange, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Connection Code',
                              style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter')),
                          Text(
                            connectionCodeAsync.isLoading &&
                                    connectionCode.isEmpty
                                ? 'Generating your code…'
                                : connectionCodeAsync.hasError &&
                                        connectionCode.isEmpty
                                    ? 'Could not generate code'
                                    : connectionCode,
                            style: TextStyle(
                                color: primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                fontFamily: 'Outfit'),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                          connectionCodeAsync.hasError && connectionCode.isEmpty
                              ? Icons.refresh_rounded
                              : Icons.copy_rounded,
                          color: AppTheme.primaryOrange,
                          size: 20),
                      onPressed: connectionCode.isEmpty
                          ? () {
                              ref.invalidate(connectionCodeProvider);
                            }
                          : () {
                              Clipboard.setData(
                                  ClipboardData(text: connectionCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Code copied to clipboard!'),
                                    duration: Duration(seconds: 2)),
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── SLIM SEGMENTED CONTROL: [ Direct Messages ] [ Interest Groups ] ──
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? AppTheme.primaryOrange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Text(
                              'Direct Messages',
                              style: TextStyle(
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : secondaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? AppTheme.primaryOrange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Text(
                              'Interest Groups',
                              style: TextStyle(
                                color: _selectedTabIndex == 1
                                    ? Colors.white
                                    : secondaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── TAB CONTENT ───────────────────────────────────────────────
              if (_selectedTabIndex == 0) ...[
                // PENDING REQUESTS
                pendingReqsAsync.when(
                  data: (requests) {
                    if (requests.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Incoming Requests',
                                style: TextStyle(
                                    color: primaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${requests.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...requests.map((req) => _buildRequestTile(req)),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),

                // DIRECT MESSAGES CONVERSATIONS
                conversationsAsync.when(
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                color: secondaryText.withValues(alpha: 0.5),
                                size: 40),
                            const SizedBox(height: 12),
                            Text('No 1-to-1 Messages Yet',
                                style: TextStyle(
                                    color: primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Enter a student\'s Connection Code to connect privately.',
                              style:
                                  TextStyle(color: secondaryText, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddConnectionSheet,
                              icon: const Icon(Icons.person_add_alt_1_rounded,
                                  size: 16),
                              label: const Text('Add Connection'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: conversations.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: borderColor, height: 1),
                      itemBuilder: (ctx, index) {
                        final conv = conversations[index];
                        final currentUid = user?.uid ?? '';
                        final partnerUid = conv.participants.firstWhere(
                            (p) => p != currentUid,
                            orElse: () => '');
                        final rawDetails = conv.participantDetails[partnerUid];
                        final details = rawDetails is Map
                            ? rawDetails.map(
                                (key, value) => MapEntry(key.toString(), value))
                            : const <String, dynamic>{};
                        final partnerName =
                            details['name']?.toString() ?? 'Student';
                        final partnerPhoto = details['photoUrl']?.toString();
                        final unread =
                            (conv.unreadCounts[currentUid] as num?)?.toInt() ??
                                0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: inputFill,
                            backgroundImage: partnerPhoto != null
                                ? NetworkImage(partnerPhoto)
                                : null,
                            child: partnerPhoto == null
                                ? Text(
                                    partnerName.isNotEmpty
                                        ? partnerName[0].toUpperCase()
                                        : 'S',
                                    style: TextStyle(
                                        color: primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15))
                                : null,
                          ),
                          title: Text(partnerName,
                              style: TextStyle(
                                  color: primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  fontFamily: 'Outfit')),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              conv.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread > 0 ? primaryText : secondaryText,
                                fontWeight: unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formatTime(conv.lastMessageTimestamp),
                                  style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 11,
                                      fontFamily: 'Inter')),
                              if (unread > 0) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('$unread',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            context.push('/chat/${conv.id}', extra: {
                              'partnerUid': partnerUid,
                              'partnerName': partnerName,
                              'partnerPhoto': partnerPhoto,
                            });
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryOrange)),
                  error: (e, _) => Center(
                      child: Text("We couldn't load chats. Please try again.",
                          style: TextStyle(color: secondaryText))),
                ),
              ] else ...[
                // INTEREST GROUPS TAB CONTENT
                Row(
                  children: [
                    Expanded(
                      child: Text('Joined Communities',
                          style: TextStyle(
                              color: primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: _showExploreGroupsSheet,
                      icon: const Icon(Icons.explore_outlined,
                          size: 16, color: AppTheme.primaryOrange),
                      label: const Text('Discover',
                          style: TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: _showCreateGroupSheet,
                      icon: const Icon(Icons.add,
                          size: 16, color: AppTheme.primaryOrange),
                      label: const Text('Create',
                          style: TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                userGroupsAsync.when(
                  data: (groups) {
                    if (groups.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.groups_outlined,
                                color: secondaryText.withValues(alpha: 0.5),
                                size: 40),
                            const SizedBox(height: 12),
                            Text('No Joined Communities Yet',
                                style: TextStyle(
                                    color: primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Discover student interest groups or create your own community.',
                              style:
                                  TextStyle(color: secondaryText, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showExploreGroupsSheet,
                              icon:
                                  const Icon(Icons.explore_outlined, size: 16),
                              label: const Text('Discover Groups'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: borderColor, height: 1),
                      itemBuilder: (ctx, index) {
                        final group = groups[index];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                AppTheme.primaryOrange.withValues(alpha: 0.15),
                            child: Text(
                              group.name.isNotEmpty
                                  ? group.name[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: TextStyle(
                                      color: primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      fontFamily: 'Outfit'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  group.category,
                                  style: const TextStyle(
                                      color: AppTheme.primaryOrange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              group.lastMessageSenderName.isNotEmpty
                                  ? '${group.lastMessageSenderName}: ${group.lastMessage}'
                                  : group.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 13,
                                  fontFamily: 'Inter'),
                            ),
                          ),
                          trailing: Text(
                              _formatTime(group.lastMessageTimestamp),
                              style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 11,
                                  fontFamily: 'Inter')),
                          onTap: () {
                            context.push('/group_chat/${group.id}');
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryOrange)),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "We couldn't load communities.",
                          style: TextStyle(color: secondaryText),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(userGroupsProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTile(ConnectionRequestModel req) {
    final primaryText = AppTheme.primaryTextColor(context);
    final secondaryText = AppTheme.secondaryTextColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final inputFill = AppTheme.inputFillColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: inputFill,
            backgroundImage: req.senderPhotoUrl != null
                ? NetworkImage(req.senderPhotoUrl!)
                : null,
            child: req.senderPhotoUrl == null
                ? Text(
                    req.senderName.isNotEmpty
                        ? req.senderName[0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.senderName,
                    style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Outfit')),
                Text('Year ${req.senderYear} · ${req.senderDepartment}',
                    style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontFamily: 'Inter')),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(chatRepositoryProvider)
                    .acceptConnectionRequest(req);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Connected with ${req.senderName}!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          "We couldn't accept that request. Please try again.")));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Accept',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
