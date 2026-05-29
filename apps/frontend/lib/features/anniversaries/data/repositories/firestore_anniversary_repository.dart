import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/anniversary.dart';
import 'anniversary_repository.dart';

class FirestoreAnniversaryRepository implements AnniversaryRepository {
  FirestoreAnniversaryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Anniversary>> fetchAnniversaries({
    required String coupleId,
    required String userId,
  }) async {
    final snapshot = await _anniversariesCollection(
      coupleId,
    ).where(AnniversaryFields.deletedAt, isNull: true).get();
    return snapshot.docs
        .map((doc) => _AnniversaryMapper.fromDocument(doc))
        .toList()
      ..sort((a, b) => a.baseDate.compareTo(b.baseDate));
  }

  @override
  Future<Anniversary> createAnniversary({
    required String coupleId,
    required String userId,
    required AnniversaryDraft draft,
  }) async {
    final doc = _anniversariesCollection(coupleId).doc();
    final now = DateTime.now().toUtc();
    final anniversary = Anniversary(
      id: doc.id,
      coupleId: coupleId,
      title: draft.title,
      baseDate: draft.baseDate,
      repeatRule: draft.repeatRule,
      calendarType: draft.calendarType,
      isLeapMonth: draft.isLeapMonth,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(_AnniversaryMapper.toMap(anniversary));
    return anniversary;
  }

  @override
  Future<void> deleteAnniversary({
    required String coupleId,
    required String anniversaryId,
    required String userId,
  }) async {
    final now = DateTime.now().toUtc();
    await _anniversariesCollection(coupleId).doc(anniversaryId).update({
      AnniversaryFields.deletedAt: Timestamp.fromDate(now),
      AnniversaryFields.updatedAt: Timestamp.fromDate(now),
    });
  }

  @override
  Future<Anniversary> updateAnniversary({
    required String coupleId,
    required String userId,
    required Anniversary anniversary,
  }) async {
    final updated = anniversary.copyWith(updatedAt: DateTime.now().toUtc());
    await _anniversariesCollection(
      coupleId,
    ).doc(anniversary.id).set(_AnniversaryMapper.toMap(updated));
    return updated;
  }

  CollectionReference<Map<String, dynamic>> _anniversariesCollection(
    String coupleId,
  ) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('anniversaries');
  }
}

class AnniversaryFields {
  static const coupleId = 'coupleId';
  static const title = 'title';
  static const baseDate = 'baseDate';
  static const repeatRule = 'repeatRule';
  static const calendarType = 'calendarType';
  static const isLeapMonth = 'isLeapMonth';
  static const createdBy = 'createdBy';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const deletedAt = 'deletedAt';
}

class _AnniversaryMapper {
  static Anniversary fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return Anniversary(
      id: doc.id,
      coupleId: data[AnniversaryFields.coupleId] as String? ?? '',
      title: data[AnniversaryFields.title] as String? ?? '',
      baseDate: _readDate(data[AnniversaryFields.baseDate]),
      repeatRule: _readRepeatRule(data[AnniversaryFields.repeatRule]),
      calendarType: _readCalendarType(data[AnniversaryFields.calendarType]),
      isLeapMonth: data[AnniversaryFields.isLeapMonth] as bool? ?? false,
      createdBy: data[AnniversaryFields.createdBy] as String? ?? '',
      createdAt: _readDate(data[AnniversaryFields.createdAt]),
      updatedAt: _readDate(data[AnniversaryFields.updatedAt]),
    );
  }

  static Map<String, dynamic> toMap(Anniversary anniversary) {
    return {
      AnniversaryFields.coupleId: anniversary.coupleId,
      AnniversaryFields.title: anniversary.title,
      AnniversaryFields.baseDate: Timestamp.fromDate(
        anniversary.baseDate.toUtc(),
      ),
      AnniversaryFields.repeatRule: anniversary.repeatRule.name,
      AnniversaryFields.calendarType: anniversary.calendarType.name,
      AnniversaryFields.isLeapMonth: anniversary.isLeapMonth,
      AnniversaryFields.createdBy: anniversary.createdBy,
      AnniversaryFields.createdAt: Timestamp.fromDate(
        anniversary.createdAt.toUtc(),
      ),
      AnniversaryFields.updatedAt: Timestamp.fromDate(
        anniversary.updatedAt.toUtc(),
      ),
      AnniversaryFields.deletedAt: null,
    };
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static AnniversaryRepeatRule _readRepeatRule(Object? value) {
    return AnniversaryRepeatRule.values.firstWhere(
      (rule) => rule.name == value,
      orElse: () => AnniversaryRepeatRule.yearly,
    );
  }

  static AnniversaryCalendarType _readCalendarType(Object? value) {
    return AnniversaryCalendarType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AnniversaryCalendarType.solar,
    );
  }
}
