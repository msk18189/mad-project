import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/deadline.dart';
import '../../models/deadline_reminder.dart';
import '../../providers/deadline_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/reminder_option_tile.dart';

class DeadlineFormScreen extends ConsumerStatefulWidget {
  final Deadline? existingDeadline;

  const DeadlineFormScreen({
    super.key,
    this.existingDeadline,
  });

  @override
  ConsumerState<DeadlineFormScreen> createState() => _DeadlineFormScreenState();
}

class _DeadlineFormScreenState extends ConsumerState<DeadlineFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;

  late DeadlineCategory _selectedCategory;
  late DeadlinePriority _selectedPriority;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late List<ReminderType> _selectedReminders;
  late List<Subtask> _subtasks;
  final TextEditingController _newSubtaskController = TextEditingController();

  bool get isEditing => widget.existingDeadline != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existingDeadline;
    _titleController = TextEditingController(text: d?.title ?? '');
    _descController = TextEditingController(text: d?.description ?? '');
    _urlController = TextEditingController(text: d?.url ?? '');
    _notesController = TextEditingController(text: d?.notes ?? '');

    final prefs = ref.read(preferencesProvider);
    _selectedCategory = d?.category ?? prefs.defaultCategory;
    _selectedPriority = d?.priority ?? prefs.defaultPriority;

    final initialDue = d?.dueDateTime ?? DateTime.now().add(const Duration(days: 2, hours: 4));
    _selectedDate = DateTime(initialDue.year, initialDue.month, initialDue.day);
    _selectedTime = TimeOfDay(hour: initialDue.hour, minute: initialDue.minute);

    if (d != null) {
      _selectedReminders = List.from(d.reminders);
      // Load exact persisted reminders if available
      Future.microtask(() async {
        try {
          final saved = await ref.read(reminderRepositoryProvider).getRemindersForDeadline(d.id);
          if (mounted && saved.isNotEmpty) {
            setState(() {
              _selectedReminders = saved.where((r) => r.isEnabled).map((r) => r.type).toList();
            });
          }
        } catch (_) {}
      });
    } else {
      // Use global default reminder preferences (Section 26)
      final defaults = ref.read(reminderNotifierProvider).defaultPreferences;
      _selectedReminders = ReminderType.values.where((t) => defaults[t] ?? true).toList();
    }
    _subtasks = d != null ? List.from(d.subtasks) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.burntOrange,
              onPrimary: Colors.white,
              surface: AppColors.softWhite,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.burntOrange,
              onPrimary: Colors.white,
              surface: AppColors.softWhite,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addSubtaskInline() {
    final text = _newSubtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(Subtask(
          id: const Uuid().v4(),
          title: text,
        ));
        _newSubtaskController.clear();
      });
    }
  }

  void _saveDeadline() {
    if (!_formKey.currentState!.validate()) return;

    final combinedDueDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final now = DateTime.now();
    final deadlineId = widget.existingDeadline?.id ?? const Uuid().v4();

    // Section 6, 25, 27: Build complete reminder configurations
    final reminderList = ReminderType.values.map((type) {
      final scheduledTime = type.calculateScheduledTime(combinedDueDateTime);
      final isEnabled = _selectedReminders.contains(type);
      return DeadlineReminder(
        id: '${deadlineId}_${type.name}',
        deadlineId: deadlineId,
        type: type,
        scheduledTime: scheduledTime,
        isEnabled: isEnabled,
        notificationId: DeadlineReminder.generateNotificationId(deadlineId, type),
        createdAt: now,
      );
    }).toList();

    final validScheduledCount = reminderList
        .where((r) => r.isEnabled && r.scheduledTime.isAfter(now))
        .length;

    final newDeadline = Deadline(
      id: deadlineId,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      category: _selectedCategory,
      priority: _selectedPriority,
      createdAt: widget.existingDeadline?.createdAt ?? now,
      updatedAt: now,
      deadlineDateTime: combinedDueDateTime,
      isCompleted: widget.existingDeadline?.isCompleted ?? false,
      completedAt: widget.existingDeadline?.completedAt,
      subtasks: _subtasks,
      reminders: _selectedReminders,
      url: _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final notifier = ref.read(deadlineNotifierProvider.notifier);
    if (isEditing) {
      notifier.updateDeadline(newDeadline, reminders: reminderList);
    } else {
      notifier.addDeadline(newDeadline, reminders: reminderList);
    }

    // Section 50: Clear, non-intrusive feedback
    String feedbackMsg;
    if (_selectedReminders.isEmpty) {
      feedbackMsg = 'Deadline saved without reminders.';
    } else if (validScheduledCount > 0) {
      feedbackMsg = isEditing
          ? 'Deadline updated · $validScheduledCount reminder(s) active.'
          : 'Deadline ticket logged · $validScheduledCount reminder(s) scheduled.';
    } else {
      feedbackMsg = 'Deadline is too close for earlier reminders.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          feedbackMsg,
          style: AppTypography.badge.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEE, MMM d, y');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      appBar: AppBar(
        title: Text(
          isEditing ? 'EDIT DEADLINE TICKET' : 'NEW DEADLINE TICKET',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              _buildSectionLabel('DEADLINE TITLE *', isDark),
              TextFormField(
                controller: _titleController,
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.darkInk : AppColors.ink,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. AI Model Submission, Physics Exam',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Date & Time Row
              _buildSectionLabel('DUE DATE & TIME *', isDark),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.softWhite,
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.ink,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: AppColors.burntOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateFormat.format(_selectedDate),
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkInk : AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.softWhite,
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.ink,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, size: 18, color: AppColors.burntOrange),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkInk : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Priority Selector
              _buildSectionLabel('PRIORITY LEVEL', isDark),
              Row(
                children: DeadlinePriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedPriority = priority);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? priority.color : (isDark ? AppColors.darkCard : AppColors.softWhite),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? AppColors.ink : (isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3)),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: AppColors.ink,
                                      offset: Offset(2, 2),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              priority.label,
                              style: AppTypography.badge.copyWith(
                                color: isSelected ? priority.textColor : (isDark ? AppColors.darkInk : AppColors.ink),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Category Selector
              _buildSectionLabel('CATEGORY', isDark),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DeadlineCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text('${category.emoji} ${category.label}'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                    selectedColor: AppColors.burntOrange,
                    labelStyle: AppTypography.badge.copyWith(
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
                      fontSize: 11,
                    ),
                    backgroundColor: isDark ? AppColors.darkCard : AppColors.softWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: isSelected ? AppColors.ink : (isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3)),
                        width: 1.2,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Reminders Selector (Section 25, 51, 81)
              _buildSectionLabel('REMIND ME', isDark),
              ...ReminderType.values.map((reminder) {
                final targetDue = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                );
                final isAvailable = reminder.isSchedulable(targetDue);
                final isSelected = _selectedReminders.contains(reminder);
                return ReminderOptionTile(
                  type: reminder,
                  isSelected: isSelected,
                  isAvailable: isAvailable,
                  onChanged: (val) {
                    setState(() {
                      if (val) {
                        _selectedReminders.add(reminder);
                      } else {
                        _selectedReminders.remove(reminder);
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 16),

              // Description Field
              _buildSectionLabel('DESCRIPTION & OBJECTIVES', isDark),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkInk : AppColors.ink,
                ),
                decoration: const InputDecoration(
                  hintText: 'What needs to be achieved before the clock hits zero?',
                ),
              ),
              const SizedBox(height: 20),

              // Subtasks List Builder
              _buildSectionLabel('INITIAL SUBTASKS (${_subtasks.length})', isDark),
              ..._subtasks.asMap().entries.map((entry) {
                final index = entry.key;
                final subtask = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.softWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: AppTypography.badge.copyWith(color: AppColors.mutedGrey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkInk : AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _subtasks.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newSubtaskController,
                      decoration: const InputDecoration(
                        hintText: 'Add subtask item...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _addSubtaskInline(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSubtaskInline,
                    child: const Text('ADD'),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDeadline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burntOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isEditing ? 'UPDATE DEADLINE TICKET' : 'CREATE DEADLINE TICKET',
                    style: AppTypography.badge.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(
          fontSize: 10.5,
          color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
