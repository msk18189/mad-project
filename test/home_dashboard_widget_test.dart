import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/models/deadline.dart';
import 'package:deadline/providers/countdown_tick_provider.dart';
import 'package:deadline/providers/deadline_provider.dart';
import 'package:deadline/screens/home/home_screen.dart';
import 'package:deadline/widgets/hero_urgent_card.dart';

class MockDeadlineNotifier extends DeadlineNotifier {
  final DeadlineState initialState;
  MockDeadlineNotifier(this.initialState);

  @override
  DeadlineState build() => initialState;
}

void main() {
  final fixedNow = DateTime(2026, 9, 30, 12, 0, 0);

  testWidgets('Home displays CLEAR CLOCK when no deadlines exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDateTimeProvider.overrideWithValue(fixedNow),
          deadlineNotifierProvider.overrideWith(
            () => MockDeadlineNotifier(const DeadlineState(deadlines: [])),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CLEAR CLOCK'), findsOneWidget);
    expect(find.text('0 ON THE CLOCK'), findsOneWidget);
    expect(find.text('+ ADD DEADLINE'), findsOneWidget);
  });

  testWidgets('Home displays ALL CLEAR when all deadlines are completed', (tester) async {
    final completedItem = Deadline(
      id: 'c1',
      title: 'Finished Project',
      category: DeadlineCategory.project,
      priority: DeadlinePriority.high,
      deadlineDateTime: fixedNow.subtract(const Duration(days: 1)),
      isCompleted: true,
      completedAt: fixedNow.subtract(const Duration(hours: 5)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDateTimeProvider.overrideWithValue(fixedNow),
          deadlineNotifierProvider.overrideWith(
            () => MockDeadlineNotifier(DeadlineState(deadlines: [completedItem])),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ALL CLEAR'), findsOneWidget);
    expect(find.text("You've cleared the board. Enjoy the quiet."), findsOneWidget);
  });

  testWidgets('Home displays THE CLOCK WON when only missed deadlines exist', (tester) async {
    final missedItem = Deadline(
      id: 'm1',
      title: 'Expired Assignment',
      category: DeadlineCategory.assignment,
      priority: DeadlinePriority.medium,
      deadlineDateTime: fixedNow.subtract(const Duration(hours: 2)),
      isCompleted: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDateTimeProvider.overrideWithValue(fixedNow),
          deadlineNotifierProvider.overrideWith(
            () => MockDeadlineNotifier(DeadlineState(deadlines: [missedItem])),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('THE CLOCK WON'), findsOneWidget);
    expect(find.textContaining('1 deadline passed'), findsOneWidget);
  });

  testWidgets('Home renders Hero card and sections when active deadlines exist', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final urgentItem = Deadline(
      id: 'u1',
      title: 'AI Urgent Project',
      category: DeadlineCategory.project,
      priority: DeadlinePriority.high,
      deadlineDateTime: fixedNow.add(const Duration(hours: 1)),
    );

    final upcomingItem = Deadline(
      id: 'u2',
      title: 'DBMS Assignment',
      category: DeadlineCategory.assignment,
      priority: DeadlinePriority.medium,
      deadlineDateTime: fixedNow.add(const Duration(days: 2)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDateTimeProvider.overrideWithValue(fixedNow),
          deadlineNotifierProvider.overrideWith(
            () => MockDeadlineNotifier(DeadlineState(deadlines: [urgentItem, upcomingItem])),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("TIME'S RUNNING"), findsOneWidget);
    expect(find.byType(HeroUrgentCard), findsOneWidget);
    expect(find.text('AI Urgent Project'), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('DBMS Assignment'), findsOneWidget);
  });
}
