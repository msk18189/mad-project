import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/profile_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/animations/press_scale.dart';
import '../../widgets/statistics/stat_block.dart';
import '../../widgets/statistics/streak_card.dart';
import '../settings/settings_screen.dart';

/// Phase 9 Profile & Personal Identity Screen (Sections 3-6)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile current) {
    final nameController = TextEditingController(text: current.name);
    final bioController = TextEditingController(text: current.bio);
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : AppColors.softWhite,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
              side: const BorderSide(color: AppColors.ink, width: 2),
            ),
            title: Text(
              'EDIT PROFILE',
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
                  Text('DISPLAY NAME', style: AppTypography.stamp.copyWith(fontSize: 10)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    maxLength: 40,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Enter your name...',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('SHORT BIO / MOTTO', style: AppTypography.stamp.copyWith(fontSize: 10)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bioController,
                    maxLength: 80,
                    style: AppTypography.bodySmall,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Focusing on what counts.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text('CANCEL', style: AppTypography.badge.copyWith(color: AppColors.mutedGrey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final trimmed = nameController.text.trim();
                  if (trimmed.isEmpty) {
                    setDialogState(() {
                      errorText = 'Name cannot be empty';
                    });
                    return;
                  }
                  await ref.read(profileProvider.notifier).updateProfile(
                        name: trimmed,
                        bio: bioController.text.trim(),
                      );
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.burntOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  'SAVE',
                  style: AppTypography.badge.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      appBar: AppBar(
        title: Text(
          'PROFILE & IDENTITY',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Editorial User Identity Card (Section 4 & 5)
            Container(
              padding: const EdgeInsets.all(20),
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
                    offset: const Offset(3.5, 3.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tactile Avatar Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.burntOrange,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.ink, width: 2.0),
                    ),
                    child: Center(
                      child: Text(
                        profile.initials,
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              profile.name.toUpperCase(),
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: isDark ? AppColors.darkInk : AppColors.ink,
                              ),
                            ),
                            PressScale(
                              onTap: () => _openEditProfileDialog(context, ref, profile),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkPaper : AppColors.paper,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'EDIT',
                                  style: AppTypography.badge.copyWith(
                                    fontSize: 9.5,
                                    color: AppColors.burntOrange,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.bio,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Performance Summary (Section 3 & 6)
            Text(
              'YOUR DEADLINE STORY',
              style: AppTypography.stamp.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatBlock(
                    label: 'COMPLETED',
                    value: '${stats.completedCount}',
                    subtitle: 'in current period',
                    accentColor: AppColors.oliveGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatBlock(
                    label: 'MISSED',
                    value: '${stats.missedCount}',
                    subtitle: stats.missedCount == 0 ? 'clean slate' : 'past due',
                    accentColor: stats.missedCount > 0 ? AppColors.danger : AppColors.mutedGrey,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatBlock(
                    label: 'ON-TIME',
                    value: stats.onTimeRate != null ? '${stats.onTimeRate!.round()}%' : '—',
                    subtitle: 'reliability',
                    accentColor: AppColors.burntOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Current Streak (Section 3)
            StreakCard(streakStats: stats.streakStats),
            const SizedBox(height: 28),

            // 4. Quick Settings Navigation (Section 3)
            Text(
              'PREFERENCES & CONTROLS',
              style: AppTypography.stamp.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softWhite,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.ink,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  _buildQuickSettingTile(
                    icon: Icons.notifications_active_outlined,
                    iconColor: AppColors.burntOrange,
                    title: 'Notifications & Reminders',
                    subtitle: 'Alert thresholds, sounds, and permissions',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildQuickSettingTile(
                    icon: Icons.palette_outlined,
                    iconColor: AppColors.petrolBlue,
                    title: 'Appearance & Theme',
                    subtitle: 'Warm Paper (Light), Dark Ink, or System',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildQuickSettingTile(
                    icon: Icons.tune_rounded,
                    iconColor: AppColors.oliveGreen,
                    title: 'Default Deadline Preferences',
                    subtitle: 'Default priority, category, and reminder alerts',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildQuickSettingTile(
                    icon: Icons.storage_outlined,
                    iconColor: AppColors.mustard,
                    title: 'Data Portability & Management',
                    subtitle: 'Export JSON, import database, or reset local vault',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 5. About Deadline (Section 23 & 24)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPaper : AppColors.paper,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 28, color: AppColors.burntOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEADLINE — Every Second Counts',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version 1.0.0+1 • Offline-First Personal Instrument',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 10.5,
                            color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return PressScale(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
