import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../couple/data/repositories/api_couple_repository.dart';
import '../../../couple/data/repositories/couple_repository.dart';
import '../../../couple/data/repositories/firestore_couple_repository.dart';
import '../../../couple/data/repositories/local_emulator_couple_repository.dart';
import '../../../couple/data/repositories/mock_couple_repository.dart';
import '../../../couple/domain/models/couple.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useFirebase) {
    return FirebaseAuthRepository();
  }
  return MockAuthRepository();
});

final coupleRepositoryProvider = Provider<CoupleRepository>((ref) {
  if (useApi) {
    return ApiCoupleRepository(baseUrl: apiBaseUrl);
  }
  if (useFirebase) {
    if (useFirebaseEmulator) {
      return LocalEmulatorCoupleRepository();
    }
    return FirestoreCoupleRepository();
  }
  return MockCoupleRepository();
});

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionState {
  const SessionState({
    required this.currentUser,
    this.currentCouple,
    this.isLoading = false,
    this.errorMessage,
  });

  final AppUser? currentUser;
  final Couple? currentCouple;
  final bool isLoading;
  final String? errorMessage;

  bool get isSignedIn => currentUser != null;

  bool get hasCouple => currentCouple != null;

  SessionState copyWith({
    AppUser? currentUser,
    Couple? currentCouple,
    bool? isLoading,
    String? errorMessage,
    bool clearCouple = false,
    bool clearError = false,
  }) {
    return SessionState(
      currentUser: currentUser ?? this.currentUser,
      currentCouple: clearCouple ? null : currentCouple ?? this.currentCouple,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  late final AuthRepository _authRepository;
  late final CoupleRepository _coupleRepository;

  @override
  SessionState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _coupleRepository = ref.watch(coupleRepositoryProvider);
    final user = _authRepository.currentUser();
    final initial = SessionState(currentUser: user, isLoading: user != null);
    if (user != null) {
      Future.microtask(() => _loadCurrentCouple(user.id));
    }
    return initial;
  }

  Future<void> _loadCurrentCouple(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final couple = await _coupleRepository.currentCouple(userId: userId);
      state = state.copyWith(
        currentCouple: couple,
        isLoading: false,
        clearCouple: couple == null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '커플 공간을 불러오지 못했어요.',
      );
    }
  }

  Future<void> reloadCouple() async {
    final user = state.currentUser;
    if (user == null) {
      return;
    }
    await _loadCurrentCouple(user.id);
  }

  Future<void> createDemoCouple({required String partnerName}) async {
    final user = state.currentUser;
    if (user == null) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final couple = await _coupleRepository.createCouple(
        userId: user.id,
        partnerName: partnerName,
      );
      state = state.copyWith(currentCouple: couple, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '커플 공간을 만들지 못했어요.',
      );
    }
  }

  Future<void> joinDemoCouple(String inviteCode) async {
    final user = state.currentUser;
    if (user == null) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final couple = await _coupleRepository.joinCouple(
        userId: user.id,
        inviteCode: inviteCode,
      );
      state = state.copyWith(currentCouple: couple, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '커플 공간에 참여하지 못했어요.',
      );
    }
  }

  Future<void> resetCouple() async {
    final user = state.currentUser;
    if (user != null) {
      await _coupleRepository.resetCouple(userId: user.id);
    }
    state = state.copyWith(clearCouple: true);
  }
}
