import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/deadline.dart';
import '../../providers/deadline_provider.dart';
import '../../widgets/deadline_ticket_card.dart';
import '../../widgets/empty_state_view.dart';
import '../deadline/deadline_detail_screen.dart';

/// Phase 6 Editorial Calendar Horizon Screen (Sections 20-26)
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allDeadlines = ref.watch(deadlineListProvider);
    final now = DateTime.now();
    final isFocusedCurrentMonth = _focusedMonth.year == now.year && _focusedMonth.month == now.month;

    // Filter deadlines for the selected day using local timezone (Section 25 & 57)
    final selectedDayDeadlines = allDeadlines.where((d) {
      final local = d.dueDateTime.toLocal();
      return _isSameDay(local, _selectedDate);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      appBar: AppBar(
        title: Text(
          'CALENDAR HORIZON',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 1.2),
        ),
        actions: [
          // Section 25: Return to Today Button
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _goToToday,
              icon: Icon(
                Icons.today_rounded,
                size: 16,
                color: isFocusedCurrentMonth ? AppColors.burntOrange : (isDark ? AppColors.darkMuted : AppColors.mutedGrey),
              ),
              label: Text(
                'TODAY',
                style: AppTypography.badge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  letterSpacing: 1.0,
                  color: isFocusedCurrentMonth ? AppColors.burntOrange : (isDark ? AppColors.darkInk : AppColors.ink),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header with Prev/Next Navigation (Section 21 & 25)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softWhite,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.ink,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : AppColors.ink,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    tooltip: 'Previous Month',
                    onPressed: _prevMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth).toUpperCase(),
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? AppColors.darkInk : AppColors.ink,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    tooltip: 'Next Month',
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weekday Labels: MON - SUN (Section 21)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: AppTypography.stamp.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Calendar Month Grid (Section 21, 22, 24)
            _buildCalendarGrid(context, allDeadlines, isDark, now),

            const SizedBox(height: 24),

            // Selected Date Header (Section 21 & 23)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED DATE',
                      style: AppTypography.stamp.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                        fontSize: 9.5,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy').format(_selectedDate).toUpperCase(),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.burntOrange,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.softWhite,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${selectedDayDeadlines.length} DEADLINE${selectedDayDeadlines.length == 1 ? '' : 'S'}',
                    style: AppTypography.badge.copyWith(
                      color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deadlines for selected day (Section 23 & 41)
            if (selectedDayDeadlines.isEmpty)
              EmptyStateView.noCalendarDeadlines()
            else
              ...selectedDayDeadlines.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: DeadlineTicketCard(
                    deadline: d,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeadlineDetailScreen(deadlineId: d.id),
                        ),
                      );
                    },
                    onToggleComplete: () {
                      ref.read(deadlineNotifierProvider.notifier).toggleComplete(d.id);
                    },
                  ),
                );
              }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, List<Deadline> deadlines, bool isDark, DateTime now) {
    // Days in current focused month (handles leap years automatically)
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1 = Monday
    final leadingEmpty = firstWeekday - 1;

    final totalSlots = leadingEmpty + daysInMonth;
    final rowCount = (totalSlots / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ink,
          width: 1.5,
        ),
      ),
      child: Column(
        children: List.generate(rowCount, (rowIdx) {
          return Row(
            children: List.generate(7, (colIdx) {
              final slotIdx = rowIdx * 7 + colIdx;
              final dayNumber = slotIdx - leadingEmpty + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 46));
              }

              final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final isToday = _isSameDay(cellDate, now);
              final isSelected = _isSameDay(cellDate, _selectedDate);

              // Check if there are deadlines on this day (Section 22: Priority-aware indicators)
              final dayItems = deadlines.where((d) {
                final local = d.dueDateTime.toLocal();
                return _isSameDay(local, cellDate);
              }).toList();

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                    });
                  },
                  child: Container(
                    height: 46,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.burntOrange
                          : (isToday ? (isDark ? AppColors.darkPaper : AppColors.paper) : Colors.transparent),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.ink
                            : (isToday ? AppColors.burntOrange : Colors.transparent),
                        width: isSelected || isToday ? 1.5 : 0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: isToday || isSelected ? FontWeight.w900 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkInk : AppColors.ink),
                          ),
                        ),
                        // Priority-aware dots (Section 22: • one, •• two, ••• multiple)
                        if (dayItems.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayItems.take(3).map((d) {
                              return Container(
                                width: 4.5,
                                height: 4.5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : d.priority.color,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
