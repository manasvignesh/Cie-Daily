import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

void main() {
  test('List streams', () async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final snapshot = await FirebaseFirestore.instance.collection('liveStreams').get();
    for (var doc in snapshot.docs) {
      print('ID: ${doc.id}, Title: ${doc.data()['title']}, CreatedAt: ${doc.data()['createdAt']}');
    }
  });
}
