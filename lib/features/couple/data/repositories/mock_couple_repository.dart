import '../../domain/models/couple.dart';
import 'couple_repository.dart';

class MockCoupleRepository implements CoupleRepository {
  final Map<String, Couple> _couplesByUser = {};

  @override
  Future<Couple?> currentCouple({required String userId}) async {
    return _couplesByUser[userId];
  }

  @override
  Future<Couple> createCouple({
    required String userId,
    required String partnerName,
  }) async {
    final couple = Couple(
      id: 'demo-couple',
      memberIds: [userId, 'demo-user-2'],
      inviteCode: 'LOVE-0427',
      partnerDisplayName: partnerName.trim().isEmpty
          ? '상대방'
          : partnerName.trim(),
      createdAt: DateTime.now(),
    );
    _couplesByUser[userId] = couple;
    return couple;
  }

  @override
  Future<Couple> joinCouple({
    required String userId,
    required String inviteCode,
  }) async {
    final couple = Couple(
      id: 'demo-couple',
      memberIds: [userId, 'demo-user-2'],
      inviteCode: inviteCode.trim().isEmpty ? 'LOVE-0427' : inviteCode.trim(),
      partnerDisplayName: '상대방',
      createdAt: DateTime.now(),
    );
    _couplesByUser[userId] = couple;
    return couple;
  }

  @override
  Future<void> resetCouple({required String userId}) async {
    _couplesByUser.remove(userId);
  }
}
