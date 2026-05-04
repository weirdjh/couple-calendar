import 'package:calendar/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creates a mock couple and shows the calendar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CoupleCalendarApp()));
    await tester.pumpAndSettle();

    expect(find.text('커플 공간 만들기'), findsOneWidget);
    await tester.tap(find.text('커플 공간 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('Couple Calendar'), findsOneWidget);
    expect(find.text('저녁 약속'), findsOneWidget);
    expect(find.text('일정'), findsOneWidget);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();

    expect(find.text('기념일'), findsOneWidget);
    expect(find.text('Todo'), findsOneWidget);

    await tester.tap(find.text('Todo'));
    await tester.pumpAndSettle();

    expect(find.text('버킷리스트'), findsOneWidget);
    expect(find.text('등산 하기'), findsOneWidget);
    expect(find.text('남산 가기'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('데이트 기록'));
    await tester.pumpAndSettle();

    expect(find.text('데이트 제목'), findsOneWidget);
    expect(find.text('기록 저장'), findsOneWidget);
  });
}
