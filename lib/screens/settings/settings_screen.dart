import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/category.dart';
import '../../models/priority.dart';
import '../../models/reminder_type.dart';
import '../../providers/deadline_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/animations/press_scale.dart';

/// Phase 9 & 10 Preferences, System Settings & Data Portability (Sections 7-26)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final StorageService _storage = StorageService();

  Future<void> _exportData() async {
    final jsonString = _storage.exportToJson();
    await Clipboard.setData(ClipboardData(text: jsonString));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Full database & preferences copied to clipboard as JSON.',
            style: AppTypography.badge.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.ink,
        ),
      );
    }
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    bool replaceExisting = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : AppColors.softWhite,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
              side: const BorderSide(color: AppColors.ink, width: 2),
            ),
            title: Text(
              'IMPORT DEADLINE DATA',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paste exported JSON payload below:',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    style: AppTypography.monoSmall.copyWith(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: '{\n  "app": "DEADLINE",\n  "deadlines": [...]\n}',
                      hintStyle: AppTypography.monoSmall.copyWith(
                        fontSize: 10,
                        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: replaceExisting,
                        activeColor: AppColors.burntOrange,
                        onChanged: (val) {
                          setDialogState(() {
                            replaceExisting = val ?? true;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Replace existing database records',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('CANCEL', style: AppTypography.badge.copyWith(color: AppColors.mutedGrey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.oliveGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  'IMPORT DATA',
                  style: AppTypography.badge.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final count = await _storage.importFromJson(
        controller.text.trim(),
        replaceExisting: replaceExisting,
      );
      await ref.read(deadlineNotifierProvider.notifier).loadDeadlines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0 ? '✓ Successfully imported $count deadlines.' : 'Import failed: malformed JSON or empty payload.',
              style: AppTypography.badge.copyWith(color: Colors.white),
            ),
            backgroundColor: count > 0 ? AppColors.oliveGreen : AppColors.danger,
          ),
        );
      }
    }
  }

  /// Section 21 & 22: Clear All Data with Notification Cancellation & Dialog Confirmation
  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkCard : AppColors.softWhite,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text(
          'CLEAR ALL DATA?',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will permanently remove:', style: AppTypography.bodySmall),
            const SizedBox(height: 8),
            Text('• Deadlines\n• Subtasks\n• History\n• Statistics source data\n• Local preferences',
                style: AppTypography.bodySmall.copyWith(height: 1.4, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('CANCEL', style: AppTypography.badge.copyWith(color: AppColors.mutedGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              'CLEAR DATA',
              style: AppTypography.badge.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. Cancel all scheduled notifications (Section 22)
      await NotificationService().cancelAll();
      // 2. Clear stored database boxes
      await _storage.clearAll();
      // 3. Refresh deadline state to clean empty
      await ref.read(deadlineNotifierProvider.notifier).clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All application data and notifications have been cleared.',
              style: AppTypography.badge.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);
    final prefs = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      appBar: AppBar(
        title: Text(
          'PREFERENCES & SYSTEM',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 1.2),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // 1. Notifications Section (Section 8, 9, 26)
          _buildHeader('NOTIFICATIONS', isDark),
          Consumer(
            builder: (context, ref, _) {
              final reminderState = ref.watch(reminderNotifierProvider);
              final reminderNotifier = ref.read(reminderNotifierProvider.notifier);

              return Container(
                decoration: _boxDecoration(isDark),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Deadline Reminders',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        reminderState.globalEnabled
                            ? 'Proactively notifies you before deadlines arrive'
                            : 'Reminders are paused. Deadlines & countdowns remain active.',
                        style: AppTypography.bodySmall,
                      ),
                      value: reminderState.globalEnabled,
                      activeThumbColor: AppColors.burntOrange,
                      onChanged: (val) async {
                        await reminderNotifier.setGlobalEnabled(val);
                      },
                    ),
                    if (reminderState.globalEnabled) ...[
                      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ListTile(
                        leading: const Icon(Icons.security_outlined, color: AppColors.petrolBlue),
                        title: Text('Notification Permissions', style: AppTypography.bodyMedium),
                        subtitle: Text('Check or grant OS notification permissions', style: AppTypography.bodySmall),
                        onTap: () async {
                          final granted = await reminderNotifier.requestNotificationPermissions();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  granted ? '✓ Notification permission granted.' : 'Notification permission was denied or unchanged.',
                                  style: AppTypography.badge.copyWith(color: Colors.white),
                                ),
                                backgroundColor: granted ? AppColors.oliveGreen : AppColors.ink,
                              ),
                            );
                          }
                        },
                      ),
                      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: AppColors.burntOrange),
                        title: Text('Send Test Alert Now', style: AppTypography.bodyMedium),
                        subtitle: Text('Verify notification sound & system alert', style: AppTypography.bodySmall),
                        onTap: () async {
                          await NotificationService().showTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '⏱️ Test notification sent to system tray.',
                                  style: AppTypography.badge.copyWith(color: Colors.white),
                                ),
                                backgroundColor: AppColors.ink,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 2. Default Deadline Settings (Section 10, 11, 12)
          _buildHeader('DEADLINE DEFAULTS', isDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _boxDecoration(isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Default Priority
                Text('DEFAULT PRIORITY', style: AppTypography.stamp.copyWith(fontSize: 10)),
                const SizedBox(height: 8),
                Row(
                  children: DeadlinePriority.values.map((prio) {
                    final isSelected = prefs.defaultPriority == prio;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: PressScale(
                          onTap: () => prefsNotifier.setDefaultPriority(prio),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? prio.color : (isDark ? AppColors.darkPaper : AppColors.softWhite),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? AppColors.ink : (isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.3)),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                prio.label.toUpperCase(),
                                style: AppTypography.badge.copyWith(
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Default Category
                Text('DEFAULT CATEGORY', style: AppTypography.stamp.copyWith(fontSize: 10)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: DeadlineCategory.values.map((cat) {
                    final isSelected = prefs.defaultCategory == cat;
                    return PressScale(
                      onTap: () => prefsNotifier.setDefaultCategory(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? cat.color : (isDark ? AppColors.darkPaper : AppColors.softWhite),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? AppColors.ink : (isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.3)),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          '${cat.emoji} ${cat.label.toUpperCase()}',
                          style: AppTypography.badge.copyWith(
                            color: isSelected ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Default Reminders
                Text('DEFAULT REMINDERS', style: AppTypography.stamp.copyWith(fontSize: 10)),
                const SizedBox(height: 8),
                Column(
                  children: ReminderType.values.map((type) {
                    final isChecked = prefs.defaultReminders.contains(type);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Text(type.iconEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(type.label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      value: isChecked,
                      activeColor: AppColors.burntOrange,
                      onChanged: (_) => prefsNotifier.toggleDefaultReminder(type),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Appearance Section (Section 13, 14, 15)
          _buildHeader('APPEARANCE & THEME', isDark),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _boxDecoration(isDark),
            child: Row(
              children: [
                _buildThemeCard(
                  title: 'System',
                  icon: Icons.brightness_auto_outlined,
                  isSelected: currentThemeMode == ThemeMode.system,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildThemeCard(
                  title: 'Warm Paper',
                  icon: Icons.light_mode_outlined,
                  isSelected: currentThemeMode == ThemeMode.light,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildThemeCard(
                  title: 'Dark Ink',
                  icon: Icons.dark_mode_outlined,
                  isSelected: currentThemeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Data Management (Section 16-22)
          _buildHeader('DATA PERSISTENCE & PORTABILITY', isDark),
          Container(
            decoration: _boxDecoration(isDark),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: AppColors.petrolBlue),
                  title: Text('Export Data (JSON)', style: AppTypography.bodyMedium),
                  subtitle: Text('Copy all deadline & profile data to clipboard', style: AppTypography.bodySmall),
                  onTap: _exportData,
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.oliveGreen),
                  title: Text('Import Data (JSON)', style: AppTypography.bodyMedium),
                  subtitle: Text('Restore or merge database from JSON payload', style: AppTypography.bodySmall),
                  onTap: _importData,
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
                  title: Text(
                    'Clear All Application Data',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                  ),
                  subtitle: Text('Erase all deadlines, subtasks, and reset vault', style: AppTypography.bodySmall),
                  onTap: _clearAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. About Screen Section (Section 23 & 24)
          _buildHeader('ABOUT DEADLINE', isDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _boxDecoration(isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.burntOrange,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.timer_outlined, color: Colors.white, size: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEADLINE',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'EVERY SECOND COUNTS.',
                          style: AppTypography.stamp.copyWith(
                            color: AppColors.burntOrange,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A focused, tactile deadline management instrument built around time passage, urgency thresholds, and subtask milestones.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Version 1.0.0+1 • Offline-First Architecture',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 10.5,
                    color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.burntOrange : (isDark ? AppColors.darkPaper : AppColors.softWhite),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.ink : (isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.3)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: AppTypography.badge.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTypography.stamp.copyWith(
          color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.softWhite,
      borderRadius: AppRadius.radiusMd,
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.ink,
        width: 1.5,
      ),
    );
  }
}
