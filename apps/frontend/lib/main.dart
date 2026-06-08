import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'features/home/presentation/controllers/home_controller.dart';

const _mockCoverImageUrl =
    'https://images.unsplash.com/photo-1769605483851-36836a6ce681'
    '?auto=format&fit=crop&q=85&w=1600';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseIfEnabled();
  runApp(
    ProviderScope(
      overrides: [
        if (useMock)
          initialHomeStateProvider.overrideWithValue(
            const HomeState(coverImageUrl: _mockCoverImageUrl),
          ),
      ],
      child: const CoupleCalendarApp(),
    ),
  );
}
