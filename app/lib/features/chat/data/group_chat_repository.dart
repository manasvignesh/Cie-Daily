import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/shared_content_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_chat_model.dart';

final groupChatRepositoryProvider = Provider<GroupChatRepository>((ref) {
  return GroupChatRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class GroupChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GroupChatRepository(this._firestore, this._auth);

  User? get _currentUser => _auth.currentUser;

  // 1. Create a new Group Chat
  Future<String> createGroup({
    required String name,
    required String description,
    required String category,
    bool isPublic = true,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Group name is required');
    if (cleanName.length > 40) {
      throw Exception('Group name cannot exceed 40 characters');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final myName =
        userData?['name'] as String? ?? user.displayName ?? 'Student';
    final myPhoto = userData?['photoUrl'] as String? ?? user.photoURL;

    final groupRef = _firestore.collection('group_chats').doc();

    final batch = _firestore.batch();

    batch.set(groupRef, {
      'name': cleanName,
      'description': description.trim(),
      'category': category.trim(),
      'photoUrl': null,
      'createdById': user.uid,
      'members': [user.uid],
      'memberDetails': {
        user.uid: {
          'name': myName,
          'photoUrl': myPhoto,
          'role': 'admin',
        }
      },
      'isPublic': isPublic,
      'lastMessage': '$myName created the community',
      'lastMessageSenderName': 'System',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final sysMsgRef = groupRef.collection('messages').doc();
    batch.set(sysMsgRef, {
      'senderId': user.uid,
      'senderName': myName,
      'senderPhotoUrl': myPhoto,
      'content': '$myName created the community "$cleanName"',
      'timestamp': FieldValue.serverTimestamp(),
      'isSystemMessage': true,
    });

    await batch.commit();
    return groupRef.id;
  }

  // 2. Join a Public Group
  Future<void> joinGroup(String groupId) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final groupDoc =
        await _firestore.collection('group_chats').doc(groupId).get();
    if (!groupDoc.exists) throw Exception('Community not found');

    final members = List<String>.from(groupDoc.data()?['members'] ?? []);
    if (members.contains(user.uid)) {
      return; // Already a member
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final myName =
        userData?['name'] as String? ?? user.displayName ?? 'Student';
    final myPhoto = userData?['photoUrl'] as String? ?? user.photoURL;

    final batch = _firestore.batch();
    final groupRef = _firestore.collection('group_chats').doc(groupId);

    batch.update(groupRef, {
      'members': FieldValue.arrayUnion([user.uid]),
      'memberDetails.${user.uid}': {
        'name': myName,
        'photoUrl': myPhoto,
        'role': 'member',
      },
      'lastMessage': '$myName joined the community',
      'lastMessageSenderName': 'System',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    final sysMsgRef = groupRef.collection('messages').doc();
    batch.set(sysMsgRef, {
      'senderId': user.uid,
      'senderName': myName,
      'senderPhotoUrl': myPhoto,
      'content': '$myName joined the community',
      'timestamp': FieldValue.serverTimestamp(),
      'isSystemMessage': true,
    });

    await batch.commit();
  }

  // 3. Leave a Group
  Future<void> leaveGroup(String groupId) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final groupDoc =
        await _firestore.collection('group_chats').doc(groupId).get();
    if (!groupDoc.exists) return;

    final data = groupDoc.data()!;
    final members = List<String>.from(data['members'] ?? []);
    final memberDetails =
        Map<String, dynamic>.from(data['memberDetails'] ?? {});
    final myName = (memberDetails[user.uid] as Map<String, dynamic>?)?['name']
            as String? ??
        'Student';

    if (!members.contains(user.uid)) return;

    final batch = _firestore.batch();
    final groupRef = _firestore.collection('group_chats').doc(groupId);

    // If sole member, delete group
    if (members.length <= 1) {
      batch.delete(groupRef);
    } else {
      batch.update(groupRef, {
        'members': FieldValue.arrayRemove([user.uid]),
        'memberDetails.${user.uid}': FieldValue.delete(),
        'lastMessage': '$myName left the community',
        'lastMessageSenderName': 'System',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      final sysMsgRef = groupRef.collection('messages').doc();
      batch.set(sysMsgRef, {
        'senderId': user.uid,
        'senderName': myName,
        'senderPhotoUrl': null,
        'content': '$myName left the community',
        'timestamp': FieldValue.serverTimestamp(),
        'isSystemMessage': true,
      });
    }

    await batch.commit();
  }

  // 4. Send Message to Group
  Future<void> sendGroupMessage(String groupId, String content) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final cleanText = content.trim();
    if (cleanText.isEmpty) return;

    final groupDoc =
        await _firestore.collection('group_chats').doc(groupId).get();
    if (!groupDoc.exists) throw Exception('Community group no longer exists');

    final data = groupDoc.data()!;
    final members = List<String>.from(data['members'] ?? []);
    if (!members.contains(user.uid)) {
      throw Exception(
          'You must be a member of this community to send messages.');
    }

    final memberDetails =
        Map<String, dynamic>.from(data['memberDetails'] ?? {});
    final myDetails = memberDetails[user.uid] as Map<String, dynamic>? ?? {};
    final myName =
        myDetails['name'] as String? ?? user.displayName ?? 'Student';
    final myPhoto = myDetails['photoUrl'] as String? ?? user.photoURL;

    final groupRef = _firestore.collection('group_chats').doc(groupId);
    final msgRef = groupRef.collection('messages').doc();

    final batch = _firestore.batch();

    batch.set(msgRef, {
      'senderId': user.uid,
      'senderName': myName,
      'senderPhotoUrl': myPhoto,
      'content': cleanText,
      'timestamp': FieldValue.serverTimestamp(),
      'isSystemMessage': false,
    });

    batch.update(groupRef, {
      'lastMessage': sharedContentPreview(cleanText),
      'lastMessageSenderName': myName,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // 5. Streams
  Stream<List<GroupChatModel>> streamUserGroups() {
    final user = _currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('group_chats')
        .where('members', arrayContains: user.uid)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final list = <GroupChatModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(GroupChatModel.fromMap(doc.data(), doc.id));
        } on Object {
          // Preserve the remaining community list when one record is invalid.
        }
      }
      list.sort(
        (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
      );
      return list;
    });
  }

  Stream<List<GroupChatModel>> streamDiscoverableGroups() {
    return _firestore
        .collection('group_chats')
        .where('isPublic', isEqualTo: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final list = <GroupChatModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(GroupChatModel.fromMap(doc.data(), doc.id));
        } on Object {
          // Preserve valid public communities when one record is malformed.
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<GroupMessageModel>> streamGroupMessages(String groupId) {
    return _firestore
        .collection('group_chats')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => GroupMessageModel.fromMap(doc.data(), doc.id))
          .toList();
      return messages.reversed.toList();
    });
  }
}
