import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/couple.dart';
import 'couple_repository.dart';

class FirestoreCoupleRepository implements CoupleRepository {
  FirestoreCoupleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Couple?> currentCouple({required String userId}) async {
    final membership = await _firestore
        .collectionGroup('members')
        .where(CoupleMemberFields.userId, isEqualTo: userId)
        .limit(1)
        .get();
    if (membership.docs.isEmpty) {
      return null;
    }

    final coupleRef = membership.docs.first.reference.parent.parent;
    if (coupleRef == null) {
      return null;
    }
    final couple = await coupleRef.get();
    if (!couple.exists) {
      return null;
    }
    return _CoupleMapper.fromDocument(couple);
  }

  @override
  Future<Couple> createCouple({
    required String userId,
    required String partnerName,
  }) async {
    final doc = _couplesCollection.doc();
    final now = DateTime.now().toUtc();
    final couple = Couple(
      id: doc.id,
      memberIds: [userId],
      inviteCode: _inviteCodeFromId(doc.id),
      partnerDisplayName: partnerName.trim().isEmpty
          ? '상대방'
          : partnerName.trim(),
      createdAt: now,
    );

    final batch = _firestore.batch();
    batch.set(doc, _CoupleMapper.toMap(couple, updatedAt: now));
    batch.set(doc.collection('members').doc(userId), {
      CoupleMemberFields.userId: userId,
      CoupleMemberFields.role: 'owner',
      CoupleMemberFields.createdAt: Timestamp.fromDate(now),
      CoupleMemberFields.updatedAt: Timestamp.fromDate(now),
    });
    batch.set(_inviteDocument(couple.inviteCode), {
      CoupleInviteFields.coupleId: couple.id,
      CoupleInviteFields.createdBy: userId,
      CoupleInviteFields.createdAt: Timestamp.fromDate(now),
      CoupleInviteFields.expiresAt: null,
      CoupleInviteFields.disabledAt: null,
    });
    await batch.commit();
    return couple;
  }

  @override
  Future<Couple> joinCouple({
    required String userId,
    required String inviteCode,
  }) async {
    final normalizedInviteCode = inviteCode.trim().toUpperCase();
    final inviteSnapshot = await _inviteDocument(normalizedInviteCode).get();
    final inviteData = inviteSnapshot.data();
    if (!inviteSnapshot.exists || inviteData == null) {
      throw StateError('Couple invite code not found.');
    }
    if (inviteData[CoupleInviteFields.disabledAt] != null) {
      throw StateError('Couple invite code is disabled.');
    }
    final expiresAt = _readNullableDate(
      inviteData[CoupleInviteFields.expiresAt],
    );
    if (expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc())) {
      throw StateError('Couple invite code is expired.');
    }

    final coupleId = inviteData[CoupleInviteFields.coupleId] as String? ?? '';
    if (coupleId.isEmpty) {
      throw StateError('Couple invite code is invalid.');
    }

    final coupleRef = _couplesCollection.doc(coupleId);
    return _firestore.runTransaction((transaction) async {
      final coupleSnapshot = await transaction.get(coupleRef);
      final couple = _CoupleMapper.fromDocument(coupleSnapshot);
      final now = DateTime.now().toUtc();
      final memberIds = {...couple.memberIds, userId}.toList();
      final updated = Couple(
        id: couple.id,
        memberIds: memberIds,
        inviteCode: couple.inviteCode,
        partnerDisplayName: couple.partnerDisplayName,
        relationshipStartDate: couple.relationshipStartDate,
        createdAt: couple.createdAt,
      );

      transaction.update(coupleRef, {
        CoupleFields.memberIds: memberIds,
        CoupleFields.updatedAt: Timestamp.fromDate(now),
      });
      transaction.set(coupleRef.collection('members').doc(userId), {
        CoupleMemberFields.userId: userId,
        CoupleMemberFields.role: 'member',
        CoupleMemberFields.createdAt: Timestamp.fromDate(now),
        CoupleMemberFields.updatedAt: Timestamp.fromDate(now),
      });
      return updated;
    });
  }

  @override
  Future<void> resetCouple({required String userId}) async {
    final membership = await _firestore
        .collectionGroup('members')
        .where(CoupleMemberFields.userId, isEqualTo: userId)
        .limit(1)
        .get();
    if (membership.docs.isEmpty) {
      return;
    }
    await membership.docs.first.reference.delete();
  }

  CollectionReference<Map<String, dynamic>> get _couplesCollection =>
      _firestore.collection('couples');

  DocumentReference<Map<String, dynamic>> _inviteDocument(String inviteCode) {
    return _firestore.collection('coupleInvites').doc(inviteCode);
  }
}

class CoupleFields {
  static const memberIds = 'memberIds';
  static const inviteCode = 'inviteCode';
  static const partnerDisplayName = 'partnerDisplayName';
  static const relationshipStartDate = 'relationshipStartDate';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}

class CoupleMemberFields {
  static const userId = 'userId';
  static const role = 'role';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}

class CoupleInviteFields {
  static const coupleId = 'coupleId';
  static const createdBy = 'createdBy';
  static const createdAt = 'createdAt';
  static const expiresAt = 'expiresAt';
  static const disabledAt = 'disabledAt';
}

class _CoupleMapper {
  static Couple fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Couple not found: ${doc.id}');
    }
    return Couple(
      id: doc.id,
      memberIds: _readStringList(data[CoupleFields.memberIds]),
      inviteCode: data[CoupleFields.inviteCode] as String? ?? '',
      partnerDisplayName: data[CoupleFields.partnerDisplayName] as String?,
      relationshipStartDate: _readNullableDate(
        data[CoupleFields.relationshipStartDate],
      ),
      createdAt: _readDate(data[CoupleFields.createdAt]),
    );
  }

  static Map<String, dynamic> toMap(
    Couple couple, {
    required DateTime updatedAt,
  }) {
    return {
      CoupleFields.memberIds: couple.memberIds,
      CoupleFields.inviteCode: couple.inviteCode,
      CoupleFields.partnerDisplayName: couple.partnerDisplayName,
      CoupleFields.relationshipStartDate: couple.relationshipStartDate == null
          ? null
          : Timestamp.fromDate(couple.relationshipStartDate!.toUtc()),
      CoupleFields.createdAt: Timestamp.fromDate(couple.createdAt.toUtc()),
      CoupleFields.updatedAt: Timestamp.fromDate(updatedAt.toUtc()),
    };
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList();
  }

  static DateTime _readDate(Object? value) {
    return _readNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}

DateTime? _readNullableDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

String _inviteCodeFromId(String id) {
  final compact = id.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toUpperCase();
  final suffix = compact.length <= 6
      ? compact.padRight(6, '0')
      : compact.substring(0, 6);
  return 'LOVE-$suffix';
}
