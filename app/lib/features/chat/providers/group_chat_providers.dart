import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_chat_repository.dart';
import '../models/group_chat_model.dart';
import '../models/chat_history_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

final userGroupsProvider =
    StreamProvider.autoDispose<List<GroupChatModel>>((ref) {
  final repo = ref.watch(groupChatRepositoryProvider);
  return repo.streamUserGroups();
});

final discoverableGroupsProvider =
    StreamProvider.autoDispose<List<GroupChatModel>>((ref) {
  final repo = ref.watch(groupChatRepositoryProvider);
  return repo.streamDiscoverableGroups();
});

final groupMessagesProvider = StateNotifierProvider.autoDispose.family<
    GroupMessagesController,
    AsyncValue<ChatHistoryState<GroupMessageModel>>,
    String>((ref, groupId) {
  return GroupMessagesController(FirebaseFirestore.instance, groupId);
});

class GroupMessagesController
    extends StateNotifier<AsyncValue<ChatHistoryState<GroupMessageModel>>> {
  GroupMessagesController(this._firestore, this._groupId)
      : super(const AsyncLoading()) {
    _listenToLatest();
  }

  static const _pageSize = 40;
  final FirebaseFirestore _firestore;
  final String _groupId;
  final Map<String, GroupMessageModel> _messages = {};
  Set<String> _latestIds = {};
  QueryDocumentSnapshot<Map<String, dynamic>>? _oldestDocument;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  Query<Map<String, dynamic>> get _query => _firestore
      .collection('group_chats')
      .doc(_groupId)
      .collection('messages')
      .orderBy('timestamp', descending: true);

  void _listenToLatest() {
    _subscription = _query.limit(_pageSize).snapshots().listen((snapshot) {
      for (final removedId in _latestIds) {
        _messages.remove(removedId);
      }
      final nextLatestIds = <String>{};
      for (final doc in snapshot.docs) {
        try {
          _messages[doc.id] = GroupMessageModel.fromMap(doc.data(), doc.id);
          nextLatestIds.add(doc.id);
        } on Object {
          // A malformed message does not invalidate the whole community chat.
        }
      }
      _latestIds = nextLatestIds;
      _oldestDocument ??= snapshot.docs.isEmpty ? null : snapshot.docs.last;
      state = AsyncData(ChatHistoryState(
        messages: _sortedMessages(),
        hasMore: snapshot.docs.length == _pageSize,
      ));
    }, onError: (Object error, StackTrace stackTrace) {
      state = AsyncError(error, stackTrace);
    });
  }

  Future<void> loadOlder() async {
    final current = state.valueOrNull;
    final cursor = _oldestDocument;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingOlder ||
        cursor == null) {
      return;
    }
    state = AsyncData(current.copyWith(
      isLoadingOlder: true,
      olderLoadFailed: false,
    ));
    try {
      final page = await _query
          .startAfterDocument(cursor)
          .limit(_pageSize)
          .get()
          .timeout(const Duration(seconds: 10));
      for (final doc in page.docs) {
        try {
          _messages[doc.id] = GroupMessageModel.fromMap(doc.data(), doc.id);
        } on Object {
          // Keep valid messages visible when a legacy record is malformed.
        }
      }
      if (page.docs.isNotEmpty) _oldestDocument = page.docs.last;
      state = AsyncData(ChatHistoryState(
        messages: _sortedMessages(),
        hasMore: page.docs.length == _pageSize,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(
        isLoadingOlder: false,
        olderLoadFailed: true,
      ));
    }
  }

  List<GroupMessageModel> _sortedMessages() {
    final result = _messages.values.toList();
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
