import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cie_connect/firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('List streams', () async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    final snapshot =
        await FirebaseFirestore.instance.collection('liveStreams').get();
    for (var doc in snapshot.docs) {
      debugPrint(
          'ID: ${doc.id}, Title: ${doc.data()['title']}, CreatedAt: ${doc.data()['createdAt']}');
    }
  },
      skip:
          'Live Firebase diagnostic; not part of the hermetic unit test suite.');
}
