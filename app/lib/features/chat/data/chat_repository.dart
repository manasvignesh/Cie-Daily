import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository(this._firestore, this._auth);

  User? get _currentUser => _auth.currentUser;

  // Helper to generate deterministic ID for pairs
  static String getPairId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // 1. Send Connection Request by Student Connection Code
  Future<String> sendConnectionRequest(String rawCode) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final cleanCode = rawCode.trim().toUpperCase();
    if (cleanCode.isEmpty) throw Exception('Please enter a connection code');

    // Query user by connectionCode
    final userQuery = await _firestore
        .collection('users')
        .where('connectionCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('Invalid Connection Code. Please verify and try again.');
    }

    final targetDoc = userQuery.docs.first;
    final targetUid = targetDoc.id;
    final targetData = targetDoc.data();
    final targetName = targetData['name'] as String? ?? 'Student';
    final targetAutoAccept = targetData['autoAcceptRequests'] as bool? ?? false;
    final targetBlocked = List<String>.from(targetData['blockedUserIds'] ?? []);

    if (targetUid == user.uid) {
      throw Exception('You cannot connect with yourself.');
    }

    if (targetBlocked.contains(user.uid)) {
      throw Exception('Unable to send connection request to this student.');
    }

    // Check current user blocked list
    final myDoc = await _firestore.collection('users').doc(user.uid).get();
    final myBlocked = List<String>.from(myDoc.data()?['blockedUserIds'] ?? []);
    if (myBlocked.contains(targetUid)) {
      throw Exception('You have blocked this student.');
    }

    // Check existing connection
    final pairId = getPairId(user.uid, targetUid);
    final connDoc = await _firestore.collection('connections').doc(pairId).get();
    if (connDoc.exists) {
      throw Exception('You are already connected with $targetName.');
    }

    // Check pending request
    final reqDocId = '${user.uid}_$targetUid';
    final reqDoc = await _firestore.collection('connection_requests').doc(reqDocId).get();
    if (reqDoc.exists && reqDoc.data()?['status'] == 'pending') {
      throw Exception('You have already sent a connection request to $targetName.');
    }

    // Get current user details for the request
    final myName = myDoc.data()?['name'] as String? ?? user.displayName ?? 'Student';
    final myPhoto = myDoc.data()?['photoUrl'] as String? ?? user.photoURL;
    final myDept = myDoc.data()?['department'] as String? ?? 'CS';
    final myYear = myDoc.data()?['yearOfStudy']?.toString() ?? '1';

    if (targetAutoAccept) {
      // Auto-accept request
      await _firestore.collection('connection_requests').doc(reqDocId).set({
        'senderId': user.uid,
        'receiverId': targetUid,
        'senderName': myName,
        'senderPhotoUrl': myPhoto,
        'senderDepartment': myDept,
        'senderYear': myYear,
        'status': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _createConnectionAndConversation(
        userA: user.uid,
        userB: targetUid,
        userAName: myName,
        userAPhoto: myPhoto,
        userBName: targetName,
        userBPhoto: targetData['photoUrl'] as String?,
      );

      return 'Connected automatically with $targetName!';
    } else {
      // Create pending request
      await _firestore.collection('connection_requests').doc(reqDocId).set({
        'senderId': user.uid,
        'receiverId': targetUid,
        'senderName': myName,
        'senderPhotoUrl': myPhoto,
        'senderDepartment': myDept,
        'senderYear': myYear,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return 'Connection request sent to $targetName!';
    }
  }

  // 2. Accept Connection Request
  Future<void> acceptConnectionRequest(ConnectionRequestModel request) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _firestore.collection('connection_requests').doc(request.id).update({
      'status': 'accepted',
    });

    final myDoc = await _firestore.collection('users').doc(user.uid).get();
    final myName = myDoc.data()?['name'] as String? ?? user.displayName ?? 'Student';
    final myPhoto = myDoc.data()?['photoUrl'] as String? ?? user.photoURL;

    await _createConnectionAndConversation(
      userA: request.senderId,
      userB: user.uid,
      userAName: request.senderName,
      userAPhoto: request.senderPhotoUrl,
      userBName: myName,
      userBPhoto: myPhoto,
    );
  }

  // Helper to create connection & conversation
  Future<void> _createConnectionAndConversation({
    required String userA,
    required String userB,
    required String userAName,
    required String? userAPhoto,
    required String userBName,
    required String? userBPhoto,
  }) async {
    final pairId = getPairId(userA, userB);

    final batch = _firestore.batch();

    final connRef = _firestore.collection('connections').doc(pairId);
    batch.set(connRef, {
      'users': [userA, userB],
      'createdAt': FieldValue.serverTimestamp(),
    });

    final convRef = _firestore.collection('conversations').doc(pairId);
    batch.set(convRef, {
      'participants': [userA, userB],
      'participantDetails': {
        userA: {'name': userAName, 'photoUrl': userAPhoto},
        userB: {'name': userBName, 'photoUrl': userBPhoto},
      },
      'lastMessage': 'Connection accepted. Start chatting!',
      'lastMessageSenderId': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCounts': {userA: 0, userB: 0},
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // 3. Decline Connection Request
  Future<void> declineConnectionRequest(String requestId) async {
    await _firestore.collection('connection_requests').doc(requestId).update({
      'status': 'declined',
    });
  }

  // 4. Send Message
  Future<void> sendMessage(String conversationId, String receiverId, String content) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final cleanText = content.trim();
    if (cleanText.isEmpty) return;

    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final batch = _firestore.batch();

    batch.set(msgRef, {
      'senderId': user.uid,
      'receiverId': receiverId,
      'content': cleanText,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    final convRef = _firestore.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'lastMessage': cleanText,
      'lastMessageSenderId': user.uid,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // 5. Mark Conversation as Read
  Future<void> markAsRead(String conversationId) async {
    final user = _currentUser;
    if (user == null) return;

    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCounts.${user.uid}': 0,
    });
  }

  // 6. Remove Connection
  Future<void> removeConnection(String conversationId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('connections').doc(conversationId));
    batch.delete(_firestore.collection('conversations').doc(conversationId));
    await batch.commit();
  }

  // 7. Block User
  Future<void> blockUser(String targetUid) async {
    final user = _currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'blockedUserIds': FieldValue.arrayUnion([targetUid]),
    });
  }
}
