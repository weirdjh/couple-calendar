import 'package:calendar/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores and clears the cover image URL', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(homeControllerProvider.notifier);
    controller.setCoverImageUrl('  https://example.com/us.jpg  ');

    expect(
      container.read(homeControllerProvider).coverImageUrl,
      'https://example.com/us.jpg',
    );

    controller.clearCoverImage();

    expect(container.read(homeControllerProvider).coverImageUrl, isNull);
  });

  test('toggles pinned events and anniversaries independently', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(homeControllerProvider.notifier);
    controller.toggleEventPin('event-1');
    controller.toggleAnniversaryPin('anniversary-1');

    var state = container.read(homeControllerProvider);
    expect(state.pinnedEventIds, {'event-1'});
    expect(state.pinnedAnniversaryIds, {'anniversary-1'});

    controller.toggleEventPin('event-1');
    controller.removeAnniversaryPin('anniversary-1');

    state = container.read(homeControllerProvider);
    expect(state.pinnedEventIds, isEmpty);
    expect(state.pinnedAnniversaryIds, isEmpty);
  });
}
