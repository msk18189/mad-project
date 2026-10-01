import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deadline_statistics.dart';
import '../services/statistics_service.dart';
import 'deadline_provider.dart';

export '../models/deadline_statistics.dart';

class StatisticsPeriodNotifier extends Notifier<StatisticsPeriod> {
  @override
  StatisticsPeriod build() => StatisticsPeriod.month;

  void setPeriod(StatisticsPeriod period) => state = period;
}

/// Currently selected statistics time period (Section 7 & 24)
final statisticsPeriodProvider = NotifierProvider<StatisticsPeriodNotifier, StatisticsPeriod>(() {
  return StatisticsPeriodNotifier();
});

/// Shared singleton service
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return const StatisticsService();
});

/// Reactive derived statistics calculated deterministically from real stored deadlines (Section 5, 6, 59)
final statisticsProvider = Provider<DeadlineStatistics>((ref) {
  final deadlines = ref.watch(deadlineListProvider);
  final period = ref.watch(statisticsPeriodProvider);
  final service = ref.watch(statisticsServiceProvider);

  return service.calculate(
    deadlines: deadlines,
    period: period,
    now: DateTime.now(),
  );
});
