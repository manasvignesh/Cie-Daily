import 'package:cie_connect/features/chat/models/chat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChatMessageModel message({
    required String id,
    required String clientId,
    ChatMessageDelivery delivery = ChatMessageDelivery.sent,
  }) =>
      ChatMessageModel(
        id: id,
        senderId: 'alice',
        receiverId: 'bob',
        content: 'Hello',
        timestamp: DateTime(2026),
        isRead: false,
        clientMessageId: clientId,
        delivery: delivery,
      );

  test('confirmed realtime message replaces its optimistic bubble', () {
    final messages = <String, ChatMessageModel>{};
    final pending = message(
      id: optimisticMessageId('request-1'),
      clientId: 'request-1',
      delivery: ChatMessageDelivery.sending,
    );
    messages[pending.id] = pending;

    reconcileConfirmedChatMessage(
      messages,
      message(id: 'server-message-1', clientId: 'request-1'),
    );

    expect(messages, hasLength(1));
    expect(messages.values.single.id, 'server-message-1');
  });

  test('retry keeps the same idempotency key and never adds a duplicate', () {
    final pending = message(
      id: optimisticMessageId('request-2'),
      clientId: 'request-2',
      delivery: ChatMessageDelivery.failed,
    );
    final retried = pending.copyWith(delivery: ChatMessageDelivery.sending);

    expect(retried.id, pending.id);
    expect(retried.clientMessageId, pending.clientMessageId);
    expect(retried.delivery, ChatMessageDelivery.sending);
  });
}
