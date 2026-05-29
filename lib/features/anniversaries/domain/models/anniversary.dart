class Anniversary {
  const Anniversary({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.baseDate,
    required this.repeatRule,
    this.calendarType = AnniversaryCalendarType.solar,
    this.isLeapMonth = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String coupleId;
  final String title;
  final DateTime baseDate;
  final AnniversaryRepeatRule repeatRule;
  final AnniversaryCalendarType calendarType;
  final bool isLeapMonth;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Anniversary copyWith({
    String? title,
    DateTime? baseDate,
    AnniversaryRepeatRule? repeatRule,
    AnniversaryCalendarType? calendarType,
    bool? isLeapMonth,
    DateTime? updatedAt,
  }) {
    return Anniversary(
      id: id,
      coupleId: coupleId,
      title: title ?? this.title,
      baseDate: baseDate ?? this.baseDate,
      repeatRule: repeatRule ?? this.repeatRule,
      calendarType: calendarType ?? this.calendarType,
      isLeapMonth: isLeapMonth ?? this.isLeapMonth,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum AnniversaryCalendarType { solar, lunar }

enum AnniversaryRepeatRule { every100Days, yearly, every100DaysAndYearly }

class AnniversaryOccurrence {
  const AnniversaryOccurrence({
    required this.anniversaryId,
    required this.title,
    required this.date,
    required this.label,
    required this.sortOrder,
    this.dayCount,
    this.yearCount,
  });

  final String anniversaryId;
  final String title;
  final DateTime date;
  final String label;
  final int sortOrder;
  final int? dayCount;
  final int? yearCount;
}
