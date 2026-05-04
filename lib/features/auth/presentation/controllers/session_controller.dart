import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../couple/domain/models/couple.dart';
import '../../domain/models/app_user.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionState {
  const SessionState({
    required this.currentUser,
    this.currentCouple,
    this.isLoading = false,
  });

  final AppUser? currentUser;
  final Couple? currentCouple;
  final bool isLoading;

  bool get isSignedIn => currentUser != null;

  bool get hasCouple => currentCouple != null;

  SessionState copyWith({
    AppUser? currentUser,
    Couple? currentCouple,
    bool? isLoading,
    bool clearCouple = false,
  }) {
    return SessionState(
      currentUser: currentUser ?? this.currentUser,
      currentCouple: clearCouple ? null : currentCouple ?? this.currentCouple,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState(
      currentUser: AppUser(id: 'demo-user-1', displayName: '나'),
    );
  }

  void createDemoCouple({
    required String partnerName,
    DateTime? relationshipStartDate,
  }) {
    final user = state.currentUser;
    if (user == null) {
      return;
    }
    state = state.copyWith(
      currentCouple: Couple(
        id: 'demo-couple',
        memberIds: [user.id, 'demo-user-2'],
        inviteCode: 'LOVE-0427',
        partnerDisplayName: partnerName.trim().isEmpty
            ? '상대방'
            : partnerName.trim(),
        relationshipStartDate: relationshipStartDate,
        createdAt: DateTime.now(),
      ),
    );
  }

  void joinDemoCouple(String inviteCode) {
    final user = state.currentUser;
    if (user == null) {
      return;
    }
    state = state.copyWith(
      currentCouple: Couple(
        id: 'demo-couple',
        memberIds: [user.id, 'demo-user-2'],
        inviteCode: inviteCode.trim().isEmpty ? 'LOVE-0427' : inviteCode.trim(),
        partnerDisplayName: '상대방',
        relationshipStartDate: DateTime.now().subtract(
          const Duration(days: 365),
        ),
        createdAt: DateTime.now(),
      ),
    );
  }

  void resetCouple() {
    state = state.copyWith(clearCouple: true);
  }
}
