import 'package:firebase_core/firebase_core.dart';

// If EnvConfig is not defined, define it here or ensure the import path is correct.
class EnvConfig {
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
}

class FirebaseService {
  static FirebaseOptions get currentPlatformOptions {
    return FirebaseOptions(
      apiKey: EnvConfig.firebaseApiKey,
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId: 'afrimarket-app',
      storageBucket: 'afrimarket-app.appspot.com',
    );
  }

  static Future<void> initialize() async {
    // Initialize Firebase services
    // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    // await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
}
