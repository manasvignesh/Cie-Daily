import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cie_connect/firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Populate stock articles', () async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    final batch = FirebaseFirestore.instance.batch();

    final articles = [
      {
        'title':
            'Mastering Flutter Riverpod: Best Practices for Clean Architecture',
        'description':
            'Flutter state management has evolved, and Riverpod stands out as the most robust solution for scalable apps. In this guide, we dive deep into using AsyncNotifier, structured providers, and implementing a repository pattern that makes unit testing a breeze.',
        'category': 'Article',
        'status': 'approved',
        'authorId': 'user_1', // Alice Engineer
        'primarySpaceId': 'space_flutter',
        'likesCount': 42,
        'commentsCount': 7,
        'isTodaysDrop': true,
        'mediaUrls': [
          'https://images.unsplash.com/photo-1618401471353-b98aedd07871?w=800'
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'title':
            'The Rise of Generative AI in Software Engineering: Beyond Copilot',
        'description':
            'AI assistants are no longer just completion tools. Modern software design leverages custom LLMs integrated into continuous integration pipelines to perform static analysis, auto-generate documentation, and even suggest performance refactors. Let’s explore how the role of a developer is shifting.',
        'category': 'Article',
        'status': 'approved',
        'authorId': 'user_4', // Diana AI
        'primarySpaceId': 'space_ai',
        'likesCount': 58,
        'commentsCount': 12,
        'isTodaysDrop': true,
        'mediaUrls': [
          'https://images.unsplash.com/photo-1677442136019-21780efad99a?w=800'
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'title':
            'Demystifying WebAssembly (Wasm) in 2026: Performance at Scale',
        'description':
            'WebAssembly is redefining what is possible inside the web browser. From running high-performance audio processors to running desktop-grade CAD software in client-side code, Wasm bridges the gap between native compilation and safe web execution. Here is a look at the state of Wasm today.',
        'category': 'Article',
        'status': 'approved',
        'authorId': 'user_3', // Charlie Cloud
        'primarySpaceId': 'space_web',
        'likesCount': 35,
        'commentsCount': 5,
        'isTodaysDrop': false,
        'mediaUrls': [
          'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800'
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'title':
            'Ethical Hacking: Common Web Vulnerabilities and How to Mitigate Them',
        'description':
            'Security is not an afterthought. In this article, we walk through SQL injections, cross-site scripting (XSS), and broken access controls. Learn how to write secure authentication flows, sanitize user input, and defend your student projects from common attacks.',
        'category': 'Article',
        'status': 'approved',
        'authorId': 'user_2', // Bob Hacker
        'primarySpaceId': 'space_cyber',
        'likesCount': 64,
        'commentsCount': 18,
        'isTodaysDrop': false,
        'mediaUrls': [
          'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800'
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }
    ];

    for (int i = 0; i < articles.length; i++) {
      final docRef = FirebaseFirestore.instance
          .collection('posts')
          .doc('stock_article_$i');
      batch.set(docRef, articles[i]);
    }

    await batch.commit();
    debugPrint('Stock articles populated successfully!');
  },
      skip:
          'Destructive Firebase seed script; run manually against an explicit environment.');
}
