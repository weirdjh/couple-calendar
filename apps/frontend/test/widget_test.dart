import 'package:calendar/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creates a mock couple and shows the home and calendar', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CoupleCalendarApp()));
    await tester.pumpAndSettle();

    expect(find.text('커플 공간 만들기'), findsOneWidget);
    await tester.tap(find.text('커플 공간 만들기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();

    expect(find.text('오늘'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('고정'), findsOneWidget);

    await tester.tap(find.text('캘린더'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('이전 달'), findsOneWidget);
    expect(find.text('저녁 약속'), findsWidgets);
    expect(find.text('일정'), findsNothing);

    await tester.tap(find.text('저녁 약속').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '일정'), findsOneWidget);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();

    expect(find.text('기념일'), findsOneWidget);
    expect(find.text('버킷리스트'), findsOneWidget);

    await tester.tap(find.text('버킷리스트'));
    await tester.pumpAndSettle();

    expect(find.text('버킷리스트'), findsOneWidget);
    expect(find.text('카테고리 만들기'), findsNothing);
    expect(find.byTooltip('버킷리스트 카테고리 추가'), findsOneWidget);
    expect(find.text('⛰️ 등산 하기'), findsOneWidget);
    expect(find.text('남산 가기'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('데이트 기록'));
    await tester.pumpAndSettle();

    expect(find.text('데이트 제목'), findsNothing);
    expect(find.byTooltip('데이트 기록 추가'), findsOneWidget);
    expect(find.text('하남검단산 데이트'), findsOneWidget);
  });
}
