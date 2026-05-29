import '../../domain/models/couple.dart';

abstract class CoupleRepository {
  Future<Couple?> currentCouple({required String userId});

  Future<Couple> createCouple({
    required String userId,
    required String partnerName,
  });

  Future<Couple> joinCouple({
    required String userId,
    required String inviteCode,
  });

  Future<void> resetCouple({required String userId});
}
