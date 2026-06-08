import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

final initialHomeStateProvider = Provider<HomeState>((ref) {
  return const HomeState();
});

class HomeState {
  const HomeState({
    this.coverImageUrl,
    this.pinnedEventIds = const {},
    this.pinnedAnniversaryIds = const {},
  });

  final String? coverImageUrl;
  final Set<String> pinnedEventIds;
  final Set<String> pinnedAnniversaryIds;

  HomeState copyWith({
    String? coverImageUrl,
    Set<String>? pinnedEventIds,
    Set<String>? pinnedAnniversaryIds,
    bool clearCoverImage = false,
  }) {
    return HomeState(
      coverImageUrl: clearCoverImage
          ? null
          : coverImageUrl ?? this.coverImageUrl,
      pinnedEventIds: pinnedEventIds ?? this.pinnedEventIds,
      pinnedAnniversaryIds: pinnedAnniversaryIds ?? this.pinnedAnniversaryIds,
    );
  }
}

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    return ref.watch(initialHomeStateProvider);
  }

  void setCoverImageUrl(String value) {
    final next = value.trim();
    if (next.isEmpty) {
      clearCoverImage();
      return;
    }
    state = state.copyWith(coverImageUrl: next);
  }

  void clearCoverImage() {
    state = state.copyWith(clearCoverImage: true);
  }

  void toggleEventPin(String eventId) {
    final next = {...state.pinnedEventIds};
    if (!next.add(eventId)) {
      next.remove(eventId);
    }
    state = state.copyWith(pinnedEventIds: next);
  }

  void toggleAnniversaryPin(String anniversaryId) {
    final next = {...state.pinnedAnniversaryIds};
    if (!next.add(anniversaryId)) {
      next.remove(anniversaryId);
    }
    state = state.copyWith(pinnedAnniversaryIds: next);
  }

  void removeEventPin(String eventId) {
    state = state.copyWith(
      pinnedEventIds: {...state.pinnedEventIds}..remove(eventId),
    );
  }

  void removeAnniversaryPin(String anniversaryId) {
    state = state.copyWith(
      pinnedAnniversaryIds: {...state.pinnedAnniversaryIds}
        ..remove(anniversaryId),
    );
  }
}
