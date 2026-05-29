import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

enum AppDataMode { api, mock, firebase }

const appDataModeName = String.fromEnvironment(
  'APP_DATA_MODE',
  defaultValue: 'api',
);
AppDataMode get appDataMode {
  return switch (appDataModeName) {
    'mock' => AppDataMode.mock,
    'firebase' => AppDataMode.firebase,
    _ => AppDataMode.api,
  };
}

bool get useApi => appDataMode == AppDataMode.api;
bool get useMock => appDataMode == AppDataMode.mock;
bool get useFirebase => appDataMode == AppDataMode.firebase;
const useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
const firestoreEmulatorHost = String.fromEnvironment(
  'FIRESTORE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);
const firestoreEmulatorPort = int.fromEnvironment(
  'FIRESTORE_EMULATOR_PORT',
  defaultValue: 8085,
);
const authEmulatorHost = String.fromEnvironment(
  'AUTH_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);
const authEmulatorPort = int.fromEnvironment(
  'AUTH_EMULATOR_PORT',
  defaultValue: 9099,
);
const localDemoCoupleId = String.fromEnvironment(
  'LOCAL_DEMO_COUPLE_ID',
  defaultValue: 'demo-couple',
);
const localDemoUserId = String.fromEnvironment(
  'LOCAL_DEMO_USER_ID',
  defaultValue: 'demo-user-1',
);
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8088',
);

Future<void> initializeFirebaseIfEnabled() async {
  if (!useFirebase) {
    return;
  }

  await Firebase.initializeApp(
    options: useFirebaseEmulator
        ? _localEmulatorOptions
        : DefaultFirebaseOptions.currentPlatform,
  );

  if (!useFirebaseEmulator) {
    return;
  }

  FirebaseFirestore.instance.useFirestoreEmulator(
    firestoreEmulatorHost,
    firestoreEmulatorPort,
  );
  await FirebaseAuth.instance.useAuthEmulator(
    authEmulatorHost,
    authEmulatorPort,
  );

  final credential = await FirebaseAuth.instance.signInAnonymously();
  final user = credential.user;
  if (user == null) {
    return;
  }

  final coupleRef = FirebaseFirestore.instance
      .collection('couples')
      .doc(localDemoCoupleId);
  await coupleRef.set({
    'id': localDemoCoupleId,
    'memberIds': [user.uid, 'local-partner'],
    'inviteCode': 'LOCAL-0000',
    'partnerDisplayName': '상대방',
    'createdAt': FieldValue.serverTimestamp(),
    'deletedAt': null,
  }, SetOptions(merge: true));

  await FirebaseFirestore.instance
      .collection('couples')
      .doc(localDemoCoupleId)
      .collection('members')
      .doc(user.uid)
      .set({
        'userId': user.uid,
        'role': 'local-owner',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  await FirebaseFirestore.instance
      .collection('coupleInvites')
      .doc('LOCAL-0000')
      .set({
        'coupleId': localDemoCoupleId,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}

const _localEmulatorOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:1234567890:web:demo-calendar',
  messagingSenderId: '1234567890',
  projectId: 'demo-calendar',
);
