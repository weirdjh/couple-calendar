import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../domain/models/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({firebase_auth.FirebaseAuth? auth})
    : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  final firebase_auth.FirebaseAuth _auth;

  @override
  AppUser? currentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      displayName: _displayName(user),
      photoUrl: user.photoURL,
    );
  }
}

String _displayName(firebase_auth.User user) {
  final displayName = user.displayName;
  if (displayName != null && displayName.trim().isNotEmpty) {
    return displayName.trim();
  }
  if (useFirebaseEmulator) {
    return '로컬 사용자';
  }
  return '나';
}
