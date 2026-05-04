import '../../../../core/time/calendar_date_utils.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/event_input.dart';

abstract class CalendarEventRepository {
  Future<List<CalendarEvent>> watchEvents({
    required String coupleId,
    required DateRange visibleRange,
  });

  Future<CalendarEvent> createEvent({
    required String coupleId,
    required String userId,
    required EventInput input,
  });

  Future<CalendarEvent> updateEvent({
    required String coupleId,
    required CalendarEvent event,
  });

  Future<void> deleteEvent({required String coupleId, required String eventId});
}
