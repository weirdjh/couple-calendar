import 'package:calendar/features/auth/data/repositories/auth_repository.dart';
import 'package:calendar/features/auth/domain/models/app_user.dart';
import 'package:calendar/features/auth/presentation/controllers/session_controller.dart';
import 'package:calendar/features/couple/data/repositories/couple_repository.dart';
import 'package:calendar/features/couple/domain/models/couple.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the current couple asynchronously', () async {
    final authRepository = _FakeAuthRepository(
      const AppUser(id: 'user-a', displayName: '나'),
    );
    final coupleRepository = _FakeCoupleRepository();
    final couple = _testCouple(userId: 'user-a');
    coupleRepository.couplesByUser['user-a'] = couple;

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        coupleRepositoryProvider.overrideWithValue(coupleRepository),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(sessionControllerProvider).isLoading, isTrue);
    await Future<void>.delayed(Duration.zero);

    final session = container.read(sessionControllerProvider);
    expect(session.isLoading, isFalse);
    expect(session.currentCouple?.id, couple.id);
  });

  test('clears a stale couple when the repository returns null', () async {
    final authRepository = _FakeAuthRepository(
      const AppUser(id: 'user-a', displayName: '나'),
    );
    final coupleRepository = _FakeCoupleRepository();

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        coupleRepositoryProvider.overrideWithValue(coupleRepository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(sessionControllerProvider.notifier)
        .createDemoCouple(partnerName: '파트너');
    expect(container.read(sessionControllerProvider).currentCouple, isNotNull);

    coupleRepository.couplesByUser.clear();
    await container.read(sessionControllerProvider.notifier).reloadCouple();

    final session = container.read(sessionControllerProvider);
    expect(session.isLoading, isFalse);
    expect(session.currentCouple, isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository(this.user);

  final AppUser? user;

  @override
  AppUser? currentUser() => user;
}

class _FakeCoupleRepository implements CoupleRepository {
  final couplesByUser = <String, Couple>{};

  @override
  Future<Couple?> currentCouple({required String userId}) async {
    return couplesByUser[userId];
  }

  @override
  Future<Couple> createCouple({
    required String userId,
    required String partnerName,
  }) async {
    final couple = _testCouple(userId: userId, partnerName: partnerName);
    couplesByUser[userId] = couple;
    return couple;
  }

  @override
  Future<Couple> joinCouple({
    required String userId,
    required String inviteCode,
  }) async {
    final couple = _testCouple(userId: userId, inviteCode: inviteCode);
    couplesByUser[userId] = couple;
    return couple;
  }

  @override
  Future<void> resetCouple({required String userId}) async {
    couplesByUser.remove(userId);
  }
}

Couple _testCouple({
  required String userId,
  String partnerName = '상대방',
  String inviteCode = 'LOVE-TEST',
}) {
  return Couple(
    id: 'couple-test',
    memberIds: [userId, 'partner-test'],
    inviteCode: inviteCode,
    partnerDisplayName: partnerName,
    createdAt: DateTime(2026),
  );
}
