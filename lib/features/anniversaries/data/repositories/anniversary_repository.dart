import '../../domain/models/anniversary.dart';

abstract class AnniversaryRepository {
  Future<List<Anniversary>> fetchAnniversaries({
    required String coupleId,
    required String userId,
  });

  Future<Anniversary> createAnniversary({
    required String coupleId,
    required String userId,
    required AnniversaryDraft draft,
  });

  Future<Anniversary> updateAnniversary({
    required String coupleId,
    required String userId,
    required Anniversary anniversary,
  });

  Future<void> deleteAnniversary({
    required String coupleId,
    required String anniversaryId,
    required String userId,
  });
}

class AnniversaryDraft {
  const AnniversaryDraft({
    required this.title,
    required this.baseDate,
    required this.repeatRule,
    required this.calendarType,
    this.isLeapMonth = false,
  });

  final String title;
  final DateTime baseDate;
  final AnniversaryRepeatRule repeatRule;
  final AnniversaryCalendarType calendarType;
  final bool isLeapMonth;
}
