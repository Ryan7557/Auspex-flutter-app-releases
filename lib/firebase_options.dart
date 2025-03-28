import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey:
        'AIzaSyCZS-O1jbVQhJI3gEMNoN4fXUdFDE-5lxk', // Get from Firebase Console
    appId:
        '1:978133577859:android:835bfdbb540aa7fcd52bb6', // Get from Firebase Console
    messagingSenderId: '978133577859', // Get from Firebase Console
    projectId: 'auspex-ccbc1', // Get from Firebase Console
    storageBucket:
        'auspex-ccbc1.firebasestorage.app', // Get from Firebase Console
  );
}
