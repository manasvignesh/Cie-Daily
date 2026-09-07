import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository(FirebaseFirestore.instance);
});

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository(this._firestore);

  static String generateConnectionCode(String name, String uid) {
    final cleanName = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase()
        .trim();
    final prefix = cleanName.isEmpty
        ? 'STUDENT'
        : (cleanName.length > 5 ? cleanName.substring(0, 5) : cleanName);

    var hash = 0;
    for (var i = 0; i < uid.length; i++) {
      hash = (hash * 31 + uid.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final suffix = hash.toRadixString(36).toUpperCase().padLeft(6, '0');
    return '$prefix-${suffix.substring(suffix.length - 6)}';
  }

  @override
  Future<String> ensureConnectionCode(String uid) async {
    if (uid.isEmpty) throw StateError('A signed-in user is required');
    final userRef = _firestore.collection('users').doc(uid);

    final userDoc = await userRef.get();
    final data = userDoc.data() ?? const <String, dynamic>{};
    final existing = data['connectionCode']?.toString().trim().toUpperCase() ?? '';
    if (existing.isNotEmpty) {
      return existing;
    }

    final name = data['name']?.toString().trim().isNotEmpty == true
        ? data['name'].toString()
        : (FirebaseAuth.instance.currentUser?.displayName ??
            (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Student'));

    for (var attempt = 0; attempt < 10; attempt++) {
      final candidate = generateConnectionCode(name, attempt == 0 ? uid : '$uid:$attempt');
      final mappingRef = _firestore.collection('connectionCodes').doc(candidate);

      try {
        final reserved = await _firestore.runTransaction((transaction) async {
          final mapping = await transaction.get(mappingRef);
          final owner = mapping.data()?['uid']?.toString();
          if (mapping.exists && owner != uid) {
            return false;
          }
          transaction.set(mappingRef, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (!userDoc.exists) {
            transaction.set(userRef, {
              'uid': uid,
              'email': FirebaseAuth.instance.currentUser?.email ?? '',
              'name': name,
              'connectionCode': candidate,
              'autoAcceptRequests': false,
              'blockedUserIds': [],
              'followers': [],
              'followersCount': 0,
              'following': [],
              'followingCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } else {
            transaction.update(userRef, {'connectionCode': candidate});
          }
          return true;
        });

        if (reserved) {
          return candidate;
        }
      } catch (_) {
        // Fallback write if transaction is interrupted
        await mappingRef.set({
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await userRef.set({'connectionCode': candidate}, SetOptions(merge: true));
        return candidate;
      }
    }

    final fallbackCode = generateConnectionCode(name, uid);
    await _firestore.collection('connectionCodes').doc(fallbackCode).set({
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await userRef.set({'connectionCode': fallbackCode}, SetOptions(merge: true));
    return fallbackCode;
  }

  @override
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String department,
    required int yearOfStudy,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);

    for (var attempt = 0; attempt < 10; attempt++) {
      final code = generateConnectionCode(fullName, attempt == 0 ? uid : '$uid:$attempt');
      final codeRef = _firestore.collection('connectionCodes').doc(code);

      try {
        await _firestore.runTransaction((transaction) async {
          final reservation = await transaction.get(codeRef);
          if (reservation.exists && reservation.data()?['uid'] != uid) {
            throw StateError('_COLLISION_');
          }
          transaction.set(
            userRef,
            {
              'email': email,
              'name': fullName,
              'department': department,
              'yearOfStudy': yearOfStudy,
              'connectionCode': code,
              'autoAcceptRequests': false,
              'blockedUserIds': [],
              'followers': [],
              'followersCount': 0,
              'following': [],
              'followingCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          transaction.set(codeRef, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
        return;
      } catch (e) {
        if (e is StateError && e.message == '_COLLISION_') {
          continue;
        }
        rethrow;
      }
    }
    throw StateError('Could not allocate a unique connection code');
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        await ensureConnectionCode(uid);
        final newDoc = await _firestore.collection('users').doc(uid).get();
        return newDoc.data();
      }
      final data = doc.data();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (data != null &&
          currentUid == uid &&
          (data['connectionCode']?.toString().trim().isEmpty ?? true)) {
        final code = await ensureConnectionCode(uid);
        data['connectionCode'] = code;
      }
      return data;
    } catch (error, stackTrace) {
      throw ErrorMapper.normalize(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> toggleFollowUser({
    required String currentUserId,
    required String targetUserId,
    required bool follow,
  }) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    final callerUid = authUser.uid;
    if (callerUid.isEmpty ||
        targetUserId.isEmpty ||
        callerUid == targetUserId) {
      return;
    }

    final currentUserRef = _firestore.collection('users').doc(callerUid);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);
    final followRef =
        _firestore.collection('follows').doc('${callerUid}_$targetUserId');

    await _firestore.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(currentUserRef);
      final targetSnapshot = await transaction.get(targetUserRef);
      final followSnapshot = await transaction.get(followRef);
      if (!currentSnapshot.exists || !targetSnapshot.exists) return;

      final currentData = currentSnapshot.data()!;
      final targetData = targetSnapshot.data()!;
      final following = List<String>.from(currentData['following'] ?? const []);
      final followers = List<String>.from(targetData['followers'] ?? const []);
      final alreadyFollowing = followSnapshot.exists &&
          following.contains(targetUserId) &&
          followers.contains(callerUid);
      if (alreadyFollowing == follow) return;

      if (follow) {
        transaction.set(followRef, {
          'followerId': callerUid,
          'targetUserId': targetUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(currentUserRef, {
          'following': FieldValue.arrayUnion([targetUserId]),
          'followingCount': FieldValue.increment(1),
        });
        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayUnion([callerUid]),
          'followersCount': FieldValue.increment(1),
        });
      } else {
        transaction.delete(followRef);
        transaction.update(currentUserRef, {
          'following': FieldValue.arrayRemove([targetUserId]),
          'followingCount': FieldValue.increment(-1),
        });
        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayRemove([callerUid]),
          'followersCount': FieldValue.increment(-1),
        });
      }
    });
  }
}

final userFollowingProvider =
    StreamProvider.autoDispose<Set<String>>((ref) async* {
  final user = await FirebaseAuth.instance
      .authStateChanges()
      .firstWhere((u) => u != null);
  if (user == null) {
    yield {};
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    if (data == null) return <String>{};
    final following = List<String>.from(data['following'] ?? []);
    return following.toSet();
  });
});

final isFollowingProvider =
    Provider.autoDispose.family<bool, String>((ref, targetUserId) {
  final followingSet = ref.watch(userFollowingProvider).value ?? {};
  return followingSet.contains(targetUserId);
});

final userProfileStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.data());
});

final connectionCodeProvider = FutureProvider.autoDispose<String>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return '';
  final repo = ref.read(userRepositoryProvider);
  return repo.ensureConnectionCode(user.uid);
});
