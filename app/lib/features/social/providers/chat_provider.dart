import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationItem {
  final String id;
  final String? name;
  final String? lastMessageText;
  final bool isGroup;

  ConversationItem({
    required this.id,
    this.name,
    this.lastMessageText,
    this.isGroup = false,
  });
}

final inboxProvider = FutureProvider<List<ConversationItem>>((ref) async {
  // Demo mock conversations
  return [
    ConversationItem(
      id: '1',
      name: 'MLRIT Innovation Club',
      lastMessageText: 'Welcome to Breakpoint!',
      isGroup: true,
    ),
    ConversationItem(
      id: '2',
      name: 'Student Support',
      lastMessageText: 'Let us know if you have any questions.',
      isGroup: false,
    ),
  ];
});
