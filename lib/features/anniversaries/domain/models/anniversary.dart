class Anniversary {
  const Anniversary({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.baseDate,
    required this.kind,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String coupleId;
  final String title;
  final DateTime baseDate;
  final AnniversaryKind kind;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum AnniversaryKind { firstMet, relationshipStart, custom }

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
