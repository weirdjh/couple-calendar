import 'package:http/http.dart' as http;

import '../../../../core/api/api_client.dart';
import '../../domain/models/couple.dart';
import 'couple_repository.dart';

class ApiCoupleRepository implements CoupleRepository {
  ApiCoupleRepository({required String baseUrl, http.Client? client})
    : _api = ApiClient(baseUrl: baseUrl, client: client);

  final ApiClient _api;

  @override
  Future<Couple?> currentCouple({required String userId}) async {
    final decoded = await _api.getJson(
      '/v1/couples/current',
      credential: ApiCredential.devUser(userId),
    );
    if (decoded == null) {
      return null;
    }
    return _CoupleApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<Couple> createCouple({
    required String userId,
    required String partnerName,
  }) async {
    final decoded = await _api.postJson(
      '/v1/couples',
      credential: ApiCredential.devUser(userId),
      body: {'partnerName': partnerName},
    );
    return _CoupleApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<Couple> joinCouple({
    required String userId,
    required String inviteCode,
  }) async {
    final decoded = await _api.postJson(
      '/v1/couples/join',
      credential: ApiCredential.devUser(userId),
      body: {'inviteCode': inviteCode},
    );
    return _CoupleApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<void> resetCouple({required String userId}) async {
    await _api.deleteJson(
      '/v1/couples/current',
      credential: ApiCredential.devUser(userId),
    );
  }
}

class _CoupleApiMapper {
  static Couple fromJson(Map<String, dynamic> json) {
    return Couple(
      id: json['id'] as String? ?? '',
      memberIds: _readStringList(json['memberIds']),
      inviteCode: json['inviteCode'] as String? ?? '',
      partnerDisplayName: json['partnerDisplayName'] as String?,
      relationshipStartDate: _readNullableDate(json['relationshipStartDate']),
      createdAt: _readDate(json['createdAt']),
    );
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList();
  }

  static DateTime _readDate(Object? value) {
    return _readNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }
}
