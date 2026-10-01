import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/countdown_utils.dart';
import '../../core/utils/time_progress.dart';
import '../../models/deadline.dart';
import '../../providers/countdown_tick_provider.dart';
import '../../providers/deadline_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/add_subtask_sheet.dart';
import '../../widgets/category_badge.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/countdown_display.dart';
import '../../widgets/deadline_progress.dart';
import '../../widgets/editorial_stamp.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/subtask_item_tile.dart';
import '../../widgets/tactile_progress_bar.dart';
import '../../widgets/time_pressure_gauge.dart';
import 'deadline_form_screen.dart';

class DeadlineDetailScreen extends ConsumerStatefulWidget {
  final String deadlineId;

  const DeadlineDetailScreen({
    super.key,
    required this.deadlineId,
  });

  @override
  ConsumerState<DeadlineDetailScreen> createState() => _DeadlineDetailScreenState();
}

class _DeadlineDetailScreenState extends ConsumerState<DeadlineDetailScreen> {
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _handleAddSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      ref.read(deadlineNotifierProvider.notifier).addSubtask(widget.deadlineId, text);
      _subtaskController.clear();
    }
  }

  Future<void> _openAddSubtaskSheet() async {
    final result = await AddSubtaskSheet.show(context);
    if (result != null && mounted) {
      final title = result['title']!;
      final desc = result['description'];
      await ref.read(deadlineNotifierProvider.notifier).addSubtask(
        widget.deadlineId,
        title,
        description: desc,
      );
    }
  }

  Future<void> _openEditSubtaskSheet(Subtask s) async {
    final result = await AddSubtaskSheet.show(context, existingSubtask: s);
    if (result != null && mounted) {
      final updated = s.copyWith(
        title: result['title']!,
        description: result['description'],
      );
      await ref.read(deadlineNotifierProvider.notifier).updateSubtask(
        widget.deadlineId,
        updated,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deadlines = ref.watch(deadlineListProvider);
    // Subscribe to tick provider so live timers & progress bars update dynamically
    ref.watch(countdownTickProvider);

    final deadlineMatches = deadlines.where((d) => d.id == widget.deadlineId);
    if (deadlineMatches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('DEADLINE')),
        body: const Center(child: Text('Deadline not found.')),
      );
    }
    final deadline = deadlineMatches.first;

    final now = DateTime.now();
    final status = deadline.getStatus(now);
    final dateFormat = DateFormat('EEEE, MMMM d, y • h:mm a');
    final timeProg = deadline.timeProgress(now);
    final pressure = deadline.calculateTimePressure(now);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      appBar: AppBar(
        title: Text(
          'DEADLINE FILE',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Deadline',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeadlineFormScreen(existingDeadline: deadline),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Delete Deadline',
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Delete Deadline?',
                content: 'This deadline ticket will be permanently removed. Every second counts.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (confirmed == true && context.mounted) {
                await ref.read(deadlineNotifierProvider.notifier).deleteDeadline(deadline.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner / Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CategoryBadge(category: deadline.category),
                    const SizedBox(width: 8),
                    PriorityBadge(priority: deadline.priority),
                  ],
                ),
                if (deadline.isCompleted)
                  const EditorialStamp(type: StampType.done)
                else if (status == DeadlineStatus.missed)
                  const EditorialStamp(type: StampType.missed)
                else if (status == DeadlineStatus.due || status == DeadlineStatus.urgent)
                  const EditorialStamp(type: StampType.urgent)
                else
                  const EditorialStamp(type: StampType.onRadar),
              ],
            ),
            const SizedBox(height: 16),

            // Deadline Title
            Text(
              deadline.title,
              style: AppTypography.displayMedium.copyWith(
                color: isDark ? AppColors.darkInk : AppColors.ink,
                decoration: deadline.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 8),

            // Due Date & Created Date
            Row(
              children: [
                Icon(
                  Icons.alarm,
                  size: 16,
                  color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateFormat.format(deadline.dueDateTime),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hero Live Countdown Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softWhite,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.ink,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : AppColors.ink,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (deadline.isCompleted) ...[
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.oliveGreen, size: 36),
                    const SizedBox(height: 6),
                    Text(
                      'COMPLETED',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.oliveGreen,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (deadline.completedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Finished ${CountdownUtils.formatRelativeDate(deadline.completedAt!, now: now)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      status == DeadlineStatus.missed ? 'DEADLINE PASSED' : 'TIME REMAINING',
                      style: AppTypography.stamp.copyWith(
                        color: status == DeadlineStatus.missed ? AppColors.danger : AppColors.burntOrange,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CountdownDisplay(
                      targetDate: deadline.dueDateTime,
                      style: CountdownStyle.detailed,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Urgency & Time Pressure Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softWhite,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.ink,
                  width: 1.5,
                ),
              ),
              child: TimePressureGauge(score: pressure),
            ),

            const SizedBox(height: 20),

            // Time Elapsed Progress (Section 14 & 16)
            TactileProgressBar(
              value: timeProg,
              label: 'TIME USED: ${TimeProgress.formatPercent(timeProg)}',
              color: AppColors.burntOrange,
              height: 12,
            ),

            const SizedBox(height: 16),

            // Task Progress (Section 11, 13, 14)
            DeadlineProgress(
              subtasks: deadline.subtasks,
              onAddFirstTask: _openAddSubtaskSheet,
            ),

            const SizedBox(height: 24),

            // Description / Brief
            if (deadline.description != null && deadline.description!.isNotEmpty) ...[
              Text(
                'BRIEF & NOTES',
                style: AppTypography.stamp.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.softWhite,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  deadline.description!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkInk : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section 53: Reminders Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REMINDERS',
                  style: AppTypography.stamp.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                    letterSpacing: 1.2,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DeadlineFormScreen(existingDeadline: deadline),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'EDIT REMINDERS',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.burntOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                final remindersAsync = ref.watch(deadlineRemindersFamily(deadline.id));
                final reminders = remindersAsync.value ?? [];

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReminderType.values.map((type) {
                    final matching = reminders.where((r) => r.type == type);
                    final isEnabled = matching.isNotEmpty
                        ? matching.first.isEnabled
                        : deadline.reminders.contains(type);
                    final isFuture = type.calculateScheduledTime(deadline.deadlineDateTime).isAfter(now);
                    final isScheduled = isEnabled && isFuture && !deadline.isCompleted;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isScheduled
                            ? (isDark ? const Color(0xFF2E241E) : const Color(0xFFFDF5EE))
                            : (isDark ? AppColors.darkCard : AppColors.softWhite),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isScheduled
                              ? AppColors.burntOrange
                              : (isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.2)),
                          width: isScheduled ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(type.iconEmoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            type.label,
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11,
                              fontWeight: isScheduled ? FontWeight.bold : FontWeight.normal,
                              color: isScheduled
                                  ? (isDark ? AppColors.darkInk : AppColors.ink)
                                  : (isDark ? AppColors.darkMuted : AppColors.mutedGrey),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isScheduled
                                  ? AppColors.burntOrange
                                  : (isDark ? Colors.grey[700] : Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Section 8: TASK BREAKDOWN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TASK BREAKDOWN (${deadline.subtasks.length})',
                  style: AppTypography.stamp.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                    letterSpacing: 1.2,
                  ),
                ),
                InkWell(
                  onTap: _openAddSubtaskSheet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      '+ ADD TASK',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.burntOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subtasks list with reordering (Section 16)
            if (deadline.subtasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No subtasks yet. Break this deadline down below.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: deadline.subtasks.length,
                onReorder: (oldIndex, newIndex) {
                  ref.read(deadlineNotifierProvider.notifier).reorderSubtasks(
                    deadline.id,
                    oldIndex,
                    newIndex,
                  );
                },
                itemBuilder: (context, index) {
                  final s = deadline.subtasks[index];
                  return SubtaskItemTile(
                    key: ValueKey(s.id),
                    index: index,
                    subtask: s,
                    onToggle: () {
                      ref.read(deadlineNotifierProvider.notifier).toggleSubtask(deadline.id, s.id);
                    },
                    onDelete: () {
                      ref.read(deadlineNotifierProvider.notifier).deleteSubtask(deadline.id, s.id);
                    },
                    onEdit: () => _openEditSubtaskSheet(s),
                  );
                },
              ),

            const SizedBox(height: 10),

            // Fast Inline Add Subtask input (Section 9)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: const InputDecoration(
                      hintText: 'Quick add task title...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _handleAddSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleAddSubtask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('ADD'),
                ),
              ],
            ),

            // Section 17: Completion prompt when all subtasks are finished
            if (deadline.subtasks.isNotEmpty &&
                deadline.subtasks.every((s) => s.isCompleted) &&
                !deadline.isCompleted) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E281E) : const Color(0xFFF0F6EE),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.oliveGreen, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.oliveGreen, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'ALL TASKS COMPLETE',
                          style: AppTypography.stamp.copyWith(
                            color: AppColors.oliveGreen,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ready to finish this deadline? Take the final step.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(deadlineNotifierProvider.notifier).toggleComplete(deadline.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.oliveGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'MARK DEADLINE COMPLETE',
                          style: AppTypography.badge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 36),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(deadlineNotifierProvider.notifier).toggleComplete(deadline.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: deadline.isCompleted ? AppColors.ink : AppColors.oliveGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(deadline.isCompleted ? Icons.undo : Icons.check_circle_outline),
                label: Text(
                  deadline.isCompleted ? 'RESTORE DEADLINE' : 'MARK COMPLETE',
                  style: AppTypography.badge.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
