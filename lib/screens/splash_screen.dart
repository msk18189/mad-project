import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../app.dart';
import '../core/services/notification_service.dart';
import '../providers/deadline_provider.dart';
import 'deadline/deadline_detail_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Load stored real deadlines from local database, then navigate
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(deadlineNotifierProvider.notifier).loadDeadlines();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );

      // Section 34: Cold-start notification launch routing
      final payload = NotificationService.initialPayload;
      if (payload != null && payload.isNotEmpty) {
        NotificationService.initialPayload = null;
        final deadlineId = payload.startsWith('deadline:') ? payload.substring(9) : payload;
        final deadlines = ref.read(deadlineNotifierProvider).deadlines;
        if (deadlines.any((d) => d.id == deadlineId)) {
          // Open detail screen on top of home
          appNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => DeadlineDetailScreen(deadlineId: deadlineId),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Editorial Logo Block
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.softWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.ink,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black54 : AppColors.ink,
                        offset: const Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.burntOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.timer_sharp,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'DEADLINE',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 32,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkInk : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'EVERY SECOND COUNTS.',
                  style: AppTypography.stamp.copyWith(
                    color: AppColors.burntOrange,
                    fontSize: 13,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tactile Time Management System',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
