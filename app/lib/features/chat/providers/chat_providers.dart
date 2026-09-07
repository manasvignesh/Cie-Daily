import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../models/chat_history_state.dart';
import 'dart:async';
import 'dart:developer' as developer;

final pendingRequestsProvider =
    StreamProvider.autoDispose<List<ConnectionRequestModel>>((ref) async* {
  final user = await FirebaseAuth.instance
      .authStateChanges()
      .firstWhere((u) => u != null);
  if (user == null) {
    yield [];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('connection_requests')
      .where('receiverId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .limit(50)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => ConnectionRequestModel.fromMap(doc.data(), doc.id))
        .toList();
  });
});

final conversationsProvider =
    StreamProvider.autoDispose<List<ConversationModel>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  const collectionPath = 'conversations';
  developer.log(
    'uid=${user.uid}; collection=$collectionPath; query=participants arrayContains uid; limit=100',
    name: 'cie.chat.inbox',
  );
  try {
    await for (final snapshot in FirebaseFirestore.instance
        .collection(collectionPath)
        .where('participants', arrayContains: user.uid)
        .limit(100)
        .snapshots()) {
      developer.log('documents=${snapshot.docs.length}',
          name: 'cie.chat.inbox');
      final list = <ConversationModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(ConversationModel.fromMap(doc.data(), doc.id));
        } on Object catch (error, stackTrace) {
          developer.log(
            'parse_failed document=${doc.id} errorType=${error.runtimeType} error=$error',
            name: 'cie.chat.inbox',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      list.sort(
          (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));
      yield list;
    }
  } on FirebaseException catch (error, stackTrace) {
    developer.log(
      'firestore_failed uid=${user.uid}; collection=$collectionPath; code=${error.code}; message=${error.message}',
      name: 'cie.chat.inbox',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  } on Object catch (error, stackTrace) {
    developer.log(
      'inbox_failed uid=${user.uid}; collection=$collectionPath; errorType=${error.runtimeType}; error=$error',
      name: 'cie.chat.inbox',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

final chatMessagesProvider = StateNotifierProvider.autoDispose.family<
    ChatMessagesController,
    AsyncValue<ChatHistoryState<ChatMessageModel>>,
    String>((ref, conversationId) {
  return ChatMessagesController(FirebaseFirestore.instance, conversationId);
});

class ChatMessagesController
    extends StateNotifier<AsyncValue<ChatHistoryState<ChatMessageModel>>> {
  ChatMessagesController(this._firestore, this._conversationId)
      : super(const AsyncLoading()) {
    _listenToLatest();
  }

  static const _pageSize = 40;
  final FirebaseFirestore _firestore;
  final String _conversationId;
  final Map<String, ChatMessageModel> _messages = {};
  Set<String> _latestIds = {};
  QueryDocumentSnapshot<Map<String, dynamic>>? _oldestDocument;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  Query<Map<String, dynamic>> get _query => _firestore
      .collection('conversations')
      .doc(_conversationId)
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
          final confirmed = ChatMessageModel.fromMap(doc.data(), doc.id);
          reconcileConfirmedChatMessage(_messages, confirmed);
          nextLatestIds.add(doc.id);
        } on Object {
          // Isolate malformed legacy messages instead of breaking the thread.
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

  void addOptimistic({
    required String clientMessageId,
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    final id = optimisticMessageId(clientMessageId);
    _messages[id] = ChatMessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      clientMessageId: clientMessageId,
      delivery: ChatMessageDelivery.sending,
    );
    _emit();
  }

  void markFailed(String clientMessageId) {
    final id = optimisticMessageId(clientMessageId);
    final current = _messages[id];
    if (current == null) return;
    _messages[id] = current.copyWith(delivery: ChatMessageDelivery.failed);
    _emit();
  }

  void markAccepted(String clientMessageId, {String? messageId}) {
    final id = optimisticMessageId(clientMessageId);
    final current = _messages[id];
    if (current == null) return;
    // Keep the optimistic bubble visible until the realtime document arrives.
    _messages[id] = current.copyWith(delivery: ChatMessageDelivery.sent);
    _emit();
  }

  void retry(String clientMessageId) {
    final id = optimisticMessageId(clientMessageId);
    final current = _messages[id];
    if (current == null) return;
    _messages[id] = current.copyWith(delivery: ChatMessageDelivery.sending);
    _emit();
  }

  void _emit() {
    final current = state.valueOrNull;
    state = AsyncData(ChatHistoryState(
      messages: _sortedMessages(),
      hasMore: current?.hasMore ?? false,
      isLoadingOlder: current?.isLoadingOlder ?? false,
      olderLoadFailed: current?.olderLoadFailed ?? false,
    ));
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
          _messages[doc.id] = ChatMessageModel.fromMap(doc.data(), doc.id);
        } on Object {
          // Ignore only the malformed record; valid history remains readable.
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

  List<ChatMessageModel> _sortedMessages() {
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
