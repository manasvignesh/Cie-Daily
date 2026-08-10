import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load Environment Variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization warning: $e");
  }

  // Initialize Hive Offline Storage
  try {
    await Hive.initFlutter();
  } catch (_) {}
  
  // Initialize Sentry for Error Monitoring
  try {
    await SentryFlutter.init(
      (options) {
        options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        const ProviderScope(
          child: CIEConnectApp(),
        ),
      ),
    );
  } catch (_) {
    runApp(
      const ProviderScope(
        child: CIEConnectApp(),
      ),
    );
  }
}
