import 'package:flutter/material.dart';

import '../domain/models/calendar_event.dart';

const currentUserColorValue = 0xFF4169E1;
const partnerUserColorValue = 0xFF7B879D;
const sharedEventColorValue = 0xFF7C6EE6;

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
