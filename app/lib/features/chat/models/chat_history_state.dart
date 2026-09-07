import 'package:flutter/foundation.dart';

@immutable
class ChatHistoryState<T> {
  const ChatHistoryState({
    required this.messages,
    required this.hasMore,
    this.isLoadingOlder = false,
    this.olderLoadFailed = false,
  });

  final List<T> messages;
  final bool hasMore;
  final bool isLoadingOlder;
  final bool olderLoadFailed;

  ChatHistoryState<T> copyWith({
    List<T>? messages,
    bool? hasMore,
    bool? isLoadingOlder,
    bool? olderLoadFailed,
  }) {
    return ChatHistoryState<T>(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      olderLoadFailed: olderLoadFailed ?? this.olderLoadFailed,
    );
  }
}
