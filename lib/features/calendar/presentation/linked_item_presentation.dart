import '../domain/models/calendar_event.dart';

String linkedItemEmoji(LinkedItemType type) {
  return switch (type) {
    LinkedItemType.todo => '🧭',
    LinkedItemType.dateRecord => '📍',
    LinkedItemType.conflict => '💬',
    LinkedItemType.anniversary => '🎉',
    LinkedItemType.review => '⭐',
    LinkedItemType.place => '🗺️',
  };
}

String linkedItemTypeLabel(LinkedItemType type) {
  return switch (type) {
    LinkedItemType.todo => '버킷리스트',
    LinkedItemType.dateRecord => '데이트 기록',
    LinkedItemType.conflict => '싸움 기록',
    LinkedItemType.anniversary => '기념일',
    LinkedItemType.review => '리뷰',
    LinkedItemType.place => '장소',
  };
}
