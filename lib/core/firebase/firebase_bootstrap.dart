import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

const useFirebase = bool.fromEnvironment('USE_FIREBASE');

Future<void> initializeFirebaseIfEnabled() async {
  if (!useFirebase) {
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
