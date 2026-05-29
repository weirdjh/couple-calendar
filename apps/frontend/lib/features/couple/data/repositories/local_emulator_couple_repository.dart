import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../domain/models/couple.dart';
import 'couple_repository.dart';

class LocalEmulatorCoupleRepository implements CoupleRepository {
  LocalEmulatorCoupleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Couple?> currentCouple({required String userId}) async {
    if (userId.trim().isEmpty) {
      return null;
    }
    await _ensureLocalMembership(userId);
    return _localCouple(userId: userId, partnerName: '상대방');
  }

  @override
  Future<Couple> createCouple({
    required String userId,
    required String partnerName,
  }) async {
    await _ensureLocalMembership(userId);
    return _localCouple(userId: userId, partnerName: partnerName);
  }

  @override
  Future<Couple> joinCouple({
    required String userId,
    required String inviteCode,
  }) async {
    await _ensureLocalMembership(userId);
    return _localCouple(userId: userId, partnerName: '상대방');
  }

  @override
  Future<void> resetCouple({required String userId}) async {
    await _firestore
        .collection('couples')
        .doc(localDemoCoupleId)
        .collection('members')
        .doc(userId)
        .delete();
  }

  Couple _localCouple({required String userId, required String partnerName}) {
    final trimmedPartnerName = partnerName.trim();
    return Couple(
      id: localDemoCoupleId,
      memberIds: [userId, 'local-partner'],
      inviteCode: 'LOCAL-0000',
      partnerDisplayName: trimmedPartnerName.isEmpty
          ? '상대방'
          : trimmedPartnerName,
      createdAt: DateTime(2026),
    );
  }

  Future<void> _ensureLocalMembership(String userId) async {
    await _firestore
        .collection('couples')
        .doc(localDemoCoupleId)
        .collection('members')
        .doc(userId)
        .set({
          'userId': userId,
          'role': 'local-owner',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
