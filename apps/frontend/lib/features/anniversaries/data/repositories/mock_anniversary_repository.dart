import '../../domain/models/anniversary.dart';
import 'anniversary_repository.dart';

class MockAnniversaryRepository implements AnniversaryRepository {
  final List<Anniversary> _anniversaries = [];
  var _nextId = 1;

  @override
  Future<List<Anniversary>> fetchAnniversaries({
    required String coupleId,
    required String userId,
  }) async {
    return _anniversaries
        .where((anniversary) => anniversary.coupleId == coupleId)
        .toList()
      ..sort((left, right) => left.baseDate.compareTo(right.baseDate));
  }

  @override
  Future<Anniversary> createAnniversary({
    required String coupleId,
    required String userId,
    required AnniversaryDraft draft,
  }) async {
    final now = DateTime.now();
    final anniversary = Anniversary(
      id: 'anniversary-${_nextId++}',
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
    _anniversaries.add(anniversary);
    return anniversary;
  }

  @override
  Future<void> deleteAnniversary({
    required String coupleId,
    required String anniversaryId,
    required String userId,
  }) async {
    _anniversaries.removeWhere(
      (anniversary) =>
          anniversary.coupleId == coupleId && anniversary.id == anniversaryId,
    );
  }

  @override
  Future<Anniversary> updateAnniversary({
    required String coupleId,
    required String userId,
    required Anniversary anniversary,
  }) async {
    final index = _anniversaries.indexWhere(
      (existing) =>
          existing.coupleId == coupleId && existing.id == anniversary.id,
    );
    if (index == -1) {
      throw StateError('Anniversary not found');
    }
    final updated = anniversary.copyWith(updatedAt: DateTime.now());
    _anniversaries[index] = updated;
    return updated;
  }
}
