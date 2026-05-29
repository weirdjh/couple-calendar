import 'package:flutter/material.dart';

import '../../links/domain/models/linked_item.dart';

export '../../links/domain/linked_item_helpers.dart';

const calendarEventLinkIcon = Icons.calendar_month_outlined;
const dateRecordLinkIcon = Icons.favorite_border;

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

String linkedItemDisplayEmoji(LinkedItem item) {
  final emoji = item.emoji;
  if (emoji != null && emoji.trim().isNotEmpty) {
    return emoji.trim();
  }
  return linkedItemEmoji(item.type);
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

IconData linkedItemTypeIcon(LinkedItemType type) {
  return switch (type) {
    LinkedItemType.todo => Icons.check_circle_outline,
    LinkedItemType.dateRecord => dateRecordLinkIcon,
    LinkedItemType.conflict => Icons.chat_bubble_outline,
    LinkedItemType.anniversary => Icons.celebration_outlined,
    LinkedItemType.review => Icons.star_border,
    LinkedItemType.place => Icons.map_outlined,
  };
}
