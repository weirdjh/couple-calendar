import 'package:calendar/features/couple/data/repositories/mock_couple_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoupleRepository contract', () {
    test('creates, joins, loads, and resets a couple', () async {
      final repository = MockCoupleRepository();

      expect(await repository.currentCouple(userId: 'user-a'), isNull);

      final created = await repository.createCouple(
        userId: 'user-a',
        partnerName: '파트너',
      );
      expect(created.id, 'demo-couple');
      expect(created.partnerDisplayName, '파트너');
      expect(created.memberIds, contains('user-a'));

      final current = await repository.currentCouple(userId: 'user-a');
      expect(current?.id, created.id);

      final joined = await repository.joinCouple(
        userId: 'user-b',
        inviteCode: 'LOVE-9999',
      );
      expect(joined.inviteCode, 'LOVE-9999');
      expect(joined.memberIds, contains('user-b'));

      await repository.resetCouple(userId: 'user-a');
      expect(await repository.currentCouple(userId: 'user-a'), isNull);
      expect(await repository.currentCouple(userId: 'user-b'), isNotNull);
    });
  });
}
