import 'package:cie_connect/features/notifications/models/notification_model.dart';
import 'package:cie_connect/features/notifications/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationDestination', () {
    test('routes each supported content type to a stable deep link', () {
      expect(
        NotificationDestination.fromData(
            {'type': 'article', 'contentId': 'article 1'})?.route,
        '/article/article%201',
      );
      expect(
        NotificationDestination.fromData(
            {'type': 'conversation', 'conversationId': 'chat-1'})?.route,
        '/chat/chat-1',
      );
      expect(
        NotificationDestination.fromData(
            {'type': 'community', 'groupId': 'group-1'})?.route,
        '/group_chat/group-1',
      );
      expect(
        NotificationDestination.fromData(
            {'type': 'space', 'spaceId': 'space-1'})?.route,
        '/spaces/space-1',
      );
    });

    test('rejects missing, unsupported, and empty destinations', () {
      expect(NotificationDestination.fromData(const {}), isNull);
      expect(
        NotificationDestination.fromData(
            const {'type': 'unknown', 'contentId': 'x'}),
        isNull,
      );
      expect(
        NotificationDestination.fromData(
            const {'type': 'article', 'contentId': '  '}),
        isNull,
      );
    });
  });

  group('NotificationModel', () {
    test('uses an epoch fallback for an invalid legacy timestamp', () {
      final model = NotificationModel.fromJson({
        'id': 'n1',
        'title': 'Update',
        'body': 'Something happened',
        'createdAt': 'not-a-date',
      });
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('rejects a malformed required payload', () {
      expect(
        () => NotificationModel.fromJson({
          'id': 'n1',
          'title': 42,
          'body': 'Something happened',
        }),
        throwsFormatException,
      );
    });
  });
}
