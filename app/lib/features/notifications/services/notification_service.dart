import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

typedef NotificationRouteCallback = void Function(String route);

@immutable
class NotificationDestination {
  const NotificationDestination(this.route);

  final String route;

  static NotificationDestination? fromData(Map<String, dynamic> data) {
    final type =
        (data['type'] ?? data['contentType'])?.toString().toLowerCase();
    final id = (data['contentId'] ??
            data['articleId'] ??
            data['conversationId'] ??
            data['groupId'] ??
            data['spaceId'] ??
            data['profileId'])
        ?.toString()
        .trim();
    if (id == null || id.isEmpty) return null;

    switch (type) {
      case 'article':
      case 'creator_content':
        return NotificationDestination('/article/${Uri.encodeComponent(id)}');
      case 'reel':
      case 'drop':
        return NotificationDestination('/reel/${Uri.encodeComponent(id)}');
      case 'chat':
      case 'conversation':
        return NotificationDestination('/chat/${Uri.encodeComponent(id)}');
      case 'community':
      case 'group':
      case 'group_chat':
        return NotificationDestination(
            '/group_chat/${Uri.encodeComponent(id)}');
      case 'space':
        return NotificationDestination('/spaces/${Uri.encodeComponent(id)}');
      case 'profile':
      case 'follow':
      case 'connection':
        return NotificationDestination('/profile/${Uri.encodeComponent(id)}');
      default:
        return null;
    }
  }
}

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openSubscription;
  StreamSubscription<String>? _tokenSubscription;
  String? _registeredToken;
  String? _registeredUserId;
  String? _permissionResolvedForUserId;
  bool _initialized = false;
  Future<void>? _syncInFlight;
  GoRouter? _router;
  final List<String> _handledMessageIds = <String>[];

  Future<void> initialize({
    required GoRouter router,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    _router = router;
    if (_initialized) return;
    _initialized = true;
    try {
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        if (!_claim(message)) return;
        final notification = message.notification;
        final title = notification?.title ?? 'CIE Daily';
        final body = notification?.body ?? 'You have a new update.';
        final destination = NotificationDestination.fromData(message.data);
        messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('$title\n$body'),
            action: destination == null
                ? null
                : SnackBarAction(
                    label: 'Open',
                    onPressed: () => _router?.push(destination.route),
                  ),
          ));
      });

      _openSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _openMessage(message);
      });
      _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
        unawaited(_persistToken(token).catchError((_) {}));
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openMessage(initialMessage);
        });
      }
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> syncForAuthenticatedUser() async {
    if (_syncInFlight != null) return _syncInFlight;
    final operation = _syncForAuthenticatedUser();
    _syncInFlight = operation;
    try {
      await operation;
    } catch (error) {
      developer.log(
        'token_sync_failed uid=${_auth.currentUser?.uid ?? 'none'} code=${error is FirebaseException ? error.code : error.runtimeType}',
        name: 'cie.notifications',
      );
    } finally {
      _syncInFlight = null;
    }
  }

  Future<void> _syncForAuthenticatedUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_permissionResolvedForUserId != user.uid) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      _permissionResolvedForUserId = user.uid;
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _persistToken(token);
    } else {
      developer.log('token_unavailable uid=${user.uid}',
          name: 'cie.notifications');
    }
  }

  Future<void> clearForLogout() async {
    final uid = _registeredUserId ?? _auth.currentUser?.uid;
    final token = _registeredToken;
    _registeredToken = null;
    _registeredUserId = null;
    _permissionResolvedForUserId = null;
    if (uid == null || token == null) return;
    try {
      await _tokenDocument(uid, token)
          .delete()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Token cleanup is best-effort. The backend must prune invalid FCM tokens.
    } finally {
      // Invalidating the installation token prevents a signed-out user from
      // receiving private pushes even when the Firestore cleanup is offline.
      try {
        await _messaging.deleteToken();
      } catch (_) {
        // A future authenticated sync obtains a fresh token.
      }
    }
  }

  Future<void> _persistToken(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;
    if (_registeredUserId == user.uid && _registeredToken == token) return;

    final previousUid = _registeredUserId;
    final previousToken = _registeredToken;
    await _tokenDocument(user.uid, token).set({
      'token': token,
      'uid': user.uid,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));

    _registeredUserId = user.uid;
    _registeredToken = token;
    developer.log(
      'token_registered uid=${user.uid} suffix=${_safeTokenSuffix(token)}',
      name: 'cie.notifications',
    );
    if (previousUid != null &&
        previousToken != null &&
        (previousUid != user.uid || previousToken != token)) {
      try {
        await _tokenDocument(previousUid, previousToken).delete();
      } catch (_) {
        // The new token is already registered; stale-token pruning remains safe.
      }
    }
  }

  String _safeTokenSuffix(String token) {
    if (token.length <= 6) return 'short';
    return token.substring(token.length - 6);
  }

  DocumentReference<Map<String, dynamic>> _tokenDocument(
      String uid, String token) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token);
  }

  bool _claim(RemoteMessage message) {
    final id = message.messageId;
    if (id == null || id.isEmpty) return true;
    if (_handledMessageIds.contains(id)) return false;
    _handledMessageIds.add(id);
    if (_handledMessageIds.length > 50) _handledMessageIds.removeAt(0);
    return true;
  }

  void _openMessage(RemoteMessage message) {
    if (!_claim(message)) return;
    final destination = NotificationDestination.fromData(message.data);
    if (destination != null) _router?.push(destination.route);
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}
