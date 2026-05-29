import 'package:flutter/material.dart';

import '../domain/models/calendar_event.dart';

const currentUserColorValue = 0xFF4D7C8A;
const partnerUserColorValue = 0xFFC67C4E;
const sharedEventColorValue = 0xFF7C6A9E;

Color eventOwnershipColor(CalendarEvent event, String currentUserId) {
  return Color(eventOwnershipColorValue(event, currentUserId));
}

int eventOwnershipColorValue(CalendarEvent event, String currentUserId) {
  if (event.isShared) {
    return sharedEventColorValue;
  }
  if (event.isOwnedBy(currentUserId)) {
    return currentUserColorValue;
  }
  return partnerUserColorValue;
}

IconData eventOwnershipIcon(CalendarEvent event, String currentUserId) {
  if (event.isShared) {
    return Icons.favorite_outline;
  }
  if (event.isOwnedBy(currentUserId)) {
    return Icons.person_outline;
  }
  return Icons.person_pin_circle_outlined;
}
