/// Runtime-only, transient countdown representation.
/// NEVER persisted to local storage (Hive).
class CountdownState {
  final Duration remaining;
  final bool isExpired;
  final bool isDue;
  final int totalSeconds;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final String formatted;
  final String formattedHero;
  final String formattedShort;
  final String semanticLabel;

  const CountdownState({
    required this.remaining,
    required this.isExpired,
    required this.isDue,
    required this.totalSeconds,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.formatted,
    required this.formattedHero,
    required this.formattedShort,
    required this.semanticLabel,
  });

  bool get isPassed => isExpired;
  Duration get totalDifference => remaining;
  String get formattedAdaptive => isExpired ? 'PASSED' : formatted;
  Map<String, int> get parts => {
        'days': days,
        'hours': hours,
        'minutes': minutes,
        'seconds': seconds,
      };

  /// Factory constructing deterministic countdown state from target date and current time
  factory CountdownState.fromDateTime(DateTime target, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = target.difference(current);

    if (diff.isNegative) {
      final passedDuration = current.difference(target);
      final passedText = _formatPassed(passedDuration);
      return CountdownState(
        remaining: Duration.zero,
        isExpired: true,
        isDue: false,
        totalSeconds: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        formatted: 'DEADLINE PASSED',
        formattedHero: 'PASSED',
        formattedShort: 'PASSED',
        semanticLabel: 'Deadline passed $passedText ago',
      );
    }

    final totalSecs = diff.inSeconds;

    if (totalSecs == 0) {
      return const CountdownState(
        remaining: Duration.zero,
        isExpired: false,
        isDue: true,
        totalSeconds: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        formatted: 'DUE NOW',
        formattedHero: 'DUE NOW',
        formattedShort: 'DUE NOW',
        semanticLabel: 'Due right now',
      );
    }

    final days = totalSecs ~/ 86400;
    final afterDays = totalSecs % 86400;
    final hours = afterDays ~/ 3600;
    final afterHours = afterDays % 3600;
    final minutes = afterHours ~/ 60;
    final seconds = afterHours % 60;

    final formatted = _formatCountdownString(days, hours, minutes, seconds);
    final formattedHero = _formatHeroString(days, hours, minutes, seconds);
    final formattedShort = _formatShortString(days, hours, minutes, seconds);
    final semantic = _formatSemanticLabel(days, hours, minutes, seconds);

    return CountdownState(
      remaining: diff,
      isExpired: false,
      isDue: totalSecs <= 7200, // <= 2 hours is due threshold
      totalSeconds: totalSecs,
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      formatted: formatted,
      formattedHero: formattedHero,
      formattedShort: formattedShort,
      semanticLabel: semantic,
    );
  }

  /// Formatting rules from Section 7:
  /// > 7 days: 12d 08h LEFT
  /// 1–7 days: 3d 14h 22m LEFT
  /// 1–24 hours: 08h 14m 32s LEFT
  /// 1–60 minutes: 42m 18s LEFT
  /// < 1 minute: 42s LEFT
  /// == 0: DUE NOW
  /// past: DEADLINE PASSED
  static String _formatCountdownString(int d, int h, int m, int s) {
    final hStr = h.toString().padLeft(2, '0');
    final mStr = m.toString().padLeft(2, '0');
    final sStr = s.toString().padLeft(2, '0');

    if (d > 7) {
      return '${d}d ${hStr}h LEFT';
    } else if (d >= 1) {
      return '${d}d ${hStr}h ${mStr}m LEFT';
    } else if (h >= 1) {
      return '${hStr}h ${mStr}m ${sStr}s LEFT';
    } else if (m >= 1) {
      return '${mStr}m ${sStr}s LEFT';
    } else {
      return '${sStr}s LEFT';
    }
  }

  static String _formatHeroString(int d, int h, int m, int s) {
    final hStr = h.toString().padLeft(2, '0');
    final mStr = m.toString().padLeft(2, '0');
    final sStr = s.toString().padLeft(2, '0');

    if (d > 0) {
      return '${d}d ${hStr}h ${mStr}m ${sStr}s';
    }
    return '$hStr : $mStr : $sStr';
  }

  static String _formatShortString(int d, int h, int m, int s) {
    if (d > 0) return '${d}d left';
    if (h > 0) return '${h}h left';
    if (m > 0) return '${m}m left';
    return '${s}s left';
  }

  static String _formatSemanticLabel(int d, int h, int m, int s) {
    final parts = <String>[];
    if (d > 0) parts.add('$d ${d == 1 ? "day" : "days"}');
    if (h > 0) parts.add('$h ${h == 1 ? "hour" : "hours"}');
    if (m > 0) parts.add('$m ${m == 1 ? "minute" : "minutes"}');
    if (s > 0 || parts.isEmpty) parts.add('$s ${s == 1 ? "second" : "seconds"}');
    return '${parts.join(", ")} remaining';
  }

  static String _formatPassed(Duration duration) {
    final secs = duration.inSeconds;
    if (secs < 60) return '${secs}s';
    final mins = duration.inMinutes;
    if (mins < 60) return '${mins}m';
    final hours = duration.inHours;
    if (hours < 24) return '${hours}h';
    return '${duration.inDays}d';
  }

  @override
  String toString() => formatted;
}
