import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../models/subtask.dart';

class AddSubtaskSheet extends StatefulWidget {
  final Subtask? existingSubtask;

  const AddSubtaskSheet({super.key, this.existingSubtask});

  static Future<Map<String, String?>?> show(
    BuildContext context, {
    Subtask? existingSubtask,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.softWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddSubtaskSheet(existingSubtask: existingSubtask),
    );
  }

  @override
  State<AddSubtaskSheet> createState() => _AddSubtaskSheetState();
}

class _AddSubtaskSheetState extends State<AddSubtaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  bool get isEditing => widget.existingSubtask != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingSubtask?.title ?? '');
    _descController =
        TextEditingController(text: widget.existingSubtask?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'EDIT TASK' : 'ADD NEW TASK',
                  style: AppTypography.titleMedium.copyWith(
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.darkInk : AppColors.ink,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Task Name Field
            Text(
              'TASK TITLE *',
              style: AppTypography.stamp.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              maxLength: 120,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkInk : AppColors.ink,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. Clean and prepare dataset',
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Task title cannot be empty.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Optional Description Field
            Text(
              'DESCRIPTION (OPTIONAL)',
              style: AppTypography.stamp.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              maxLength: 300,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkInk : AppColors.ink,
              ),
              decoration: const InputDecoration(
                hintText: 'Add notes or specific steps for this task...',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.ink,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'CANCEL',
                      style: AppTypography.badge.copyWith(
                        color: isDark ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burntOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isEditing ? 'SAVE CHANGES' : 'ADD TASK',
                      style: AppTypography.badge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
