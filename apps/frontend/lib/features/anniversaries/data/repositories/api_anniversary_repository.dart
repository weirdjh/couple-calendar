import 'package:http/http.dart' as http;

import '../../../../core/api/api_client.dart';
import '../../domain/models/anniversary.dart';
import 'anniversary_repository.dart';

class ApiAnniversaryRepository implements AnniversaryRepository {
  ApiAnniversaryRepository({required String baseUrl, http.Client? client})
    : _api = ApiClient(baseUrl: baseUrl, client: client);

  final ApiClient _api;

  @override
  Future<List<Anniversary>> fetchAnniversaries({
    required String coupleId,
    required String userId,
  }) async {
    final decoded = await _api.getJson(
      '/v1/couples/$coupleId/anniversaries',
      credential: ApiCredential.devUser(userId),
    );
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_AnniversaryApiMapper.fromJson)
        .toList()
      ..sort((a, b) => a.baseDate.compareTo(b.baseDate));
  }

  @override
  Future<Anniversary> createAnniversary({
    required String coupleId,
    required String userId,
    required AnniversaryDraft draft,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/anniversaries',
              credential: ApiCredential.devUser(userId),
              body: {'draft': _AnniversaryApiMapper.draftToJson(draft)},
            )
            as Map<String, dynamic>;
    return _AnniversaryApiMapper.fromJson(json);
  }

  @override
  Future<Anniversary> updateAnniversary({
    required String coupleId,
    required String userId,
    required Anniversary anniversary,
  }) async {
    final json =
        await _api.putJson(
              '/v1/couples/$coupleId/anniversaries/${anniversary.id}',
              credential: ApiCredential.devUser(userId),
              body: {
                'anniversary': _AnniversaryApiMapper.anniversaryToJson(
                  anniversary,
                ),
              },
            )
            as Map<String, dynamic>;
    return _AnniversaryApiMapper.fromJson(json);
  }

  @override
  Future<void> deleteAnniversary({
    required String coupleId,
    required String anniversaryId,
    required String userId,
  }) async {
    await _api.deleteJson(
      '/v1/couples/$coupleId/anniversaries/$anniversaryId',
      credential: ApiCredential.devUser(userId),
    );
  }
}

class _AnniversaryApiMapper {
  static Anniversary fromJson(Map<String, dynamic> json) {
    return Anniversary(
      id: json['id'] as String? ?? '',
      coupleId: json['coupleId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      baseDate: _readDate(json['baseDate']),
      repeatRule: _readRepeatRule(json['repeatRule']),
      calendarType: _readCalendarType(json['calendarType']),
      isLeapMonth: json['isLeapMonth'] as bool? ?? false,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  static Map<String, dynamic> draftToJson(AnniversaryDraft draft) {
    return {
      'title': draft.title,
      'baseDate': draft.baseDate.toUtc().toIso8601String(),
      'repeatRule': draft.repeatRule.name,
      'calendarType': draft.calendarType.name,
      'isLeapMonth': draft.isLeapMonth,
    };
  }

  static Map<String, dynamic> anniversaryToJson(Anniversary anniversary) {
    return {
      'id': anniversary.id,
      'coupleId': anniversary.coupleId,
      'title': anniversary.title,
      'baseDate': anniversary.baseDate.toUtc().toIso8601String(),
      'repeatRule': anniversary.repeatRule.name,
      'calendarType': anniversary.calendarType.name,
      'isLeapMonth': anniversary.isLeapMonth,
      'createdBy': anniversary.createdBy,
      'createdAt': anniversary.createdAt.toUtc().toIso8601String(),
      'updatedAt': anniversary.updatedAt.toUtc().toIso8601String(),
    };
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

  static DateTime _readDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(value)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
