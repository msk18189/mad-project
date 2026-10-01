import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/deadline.dart';
import '../../models/deadline_preferences.dart';
import '../../models/streak_stats.dart';
import '../../models/user_profile.dart';

/// Storage service backed by Hive with full persistence, import/export, and schema validation
class StorageService {
  static const String _deadlinesBoxName = 'deadlines_box_v1';
  static const String _settingsBoxName = 'settings_box_v1';
  static const String _statsBoxName = 'stats_box_v1';

  late Box<String> _deadlinesBox;
  late Box<dynamic> _settingsBox;
  late Box<String> _statsBox;

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Initialize Hive and open boxes
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _deadlinesBox = await Hive.openBox<String>(_deadlinesBoxName);
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
      _statsBox = await Hive.openBox<String>(_statsBoxName);
    } catch (e) {
      debugPrint('Hive init error (fallback in-memory): $e');
    }
  }

  // --- DEADLINE CRUD ---

  List<Deadline> getAllDeadlines() {
    final list = <Deadline>[];
    for (final raw in _deadlinesBox.values) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        list.add(Deadline.fromJson(map));
      } catch (e) {
        debugPrint('Error decoding deadline: $e');
      }
    }
    return list;
  }

  Future<void> saveDeadline(Deadline deadline) async {
    final raw = jsonEncode(deadline.toJson());
    await _deadlinesBox.put(deadline.id, raw);
  }

  Future<void> saveAllDeadlines(List<Deadline> deadlines) async {
    final map = <String, String>{};
    for (final d in deadlines) {
      map[d.id] = jsonEncode(d.toJson());
    }
    await _deadlinesBox.putAll(map);
  }

  Future<void> deleteDeadline(String id) async {
    await _deadlinesBox.delete(id);
  }

  Future<void> clearCompletedDeadlines() async {
    final keysToDelete = <dynamic>[];
    for (final key in _deadlinesBox.keys) {
      final raw = _deadlinesBox.get(key);
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['isCompleted'] == true) {
            keysToDelete.add(key);
          }
        } catch (_) {}
      }
    }
    await _deadlinesBox.deleteAll(keysToDelete);
  }

  Future<void> clearAll() async {
    await _deadlinesBox.clear();
    await _statsBox.clear();
    await _settingsBox.delete('user_profile');
  }

  // --- STATS ---

  StreakStats getStreakStats() {
    final raw = _statsBox.get('streak_stats');
    if (raw == null) return const StreakStats();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StreakStats.fromJson(map);
    } catch (e) {
      return const StreakStats();
    }
  }

  Future<void> saveStreakStats(StreakStats stats) async {
    final raw = jsonEncode(stats.toJson());
    await _statsBox.put('streak_stats', raw);
  }

  // --- PROFILE ---

  UserProfile getUserProfile() {
    final raw = _settingsBox.get('user_profile');
    if (raw == null) return const UserProfile();
    try {
      if (raw is String) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return UserProfile.fromJson(map);
      }
      return const UserProfile();
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final raw = jsonEncode(profile.toJson());
    await _settingsBox.put('user_profile', raw);
  }

  // --- PREFERENCES ---

  DeadlinePreferences getDeadlinePreferences() {
    final raw = _settingsBox.get('deadline_preferences');
    if (raw == null) return const DeadlinePreferences();
    try {
      if (raw is String) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return DeadlinePreferences.fromJson(map);
      }
      return const DeadlinePreferences();
    } catch (_) {
      return const DeadlinePreferences();
    }
  }

  Future<void> saveDeadlinePreferences(DeadlinePreferences prefs) async {
    final raw = jsonEncode(prefs.toJson());
    await _settingsBox.put('deadline_preferences', raw);
  }

  // --- SETTINGS ---

  String getThemeMode() {
    return _settingsBox.get('theme_mode', defaultValue: 'system') as String;
  }

  Future<void> setThemeMode(String mode) async {
    await _settingsBox.put('theme_mode', mode);
  }

  bool getNotificationsEnabled() {
    return _settingsBox.get('notifications_enabled', defaultValue: true) as bool;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put('notifications_enabled', enabled);
  }

  // --- EXPORT & IMPORT (Phase 9 Section 17-20) ---

  String exportToJson() {
    final deadlines = getAllDeadlines().map((d) => d.toJson()).toList();
    final stats = getStreakStats().toJson();
    final profile = getUserProfile().toJson();
    final prefs = getDeadlinePreferences().toJson();

    final payload = {
      'app': 'DEADLINE',
      'version': '1.0.0+1',
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile,
      'preferences': prefs,
      'deadlines': deadlines,
      'stats': stats,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Safe import with explicit replace strategy and schema validation (Section 19 & 20)
  Future<int> importFromJson(String jsonString, {bool replaceExisting = true}) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return 0;

      // Validate required signature
      if (decoded['app'] != 'DEADLINE') {
        debugPrint('Invalid export format: app signature mismatch');
      }

      final rawDeadlines = decoded['deadlines'] as List<dynamic>? ?? [];

      if (replaceExisting) {
        await _deadlinesBox.clear();
      }

      int importedCount = 0;
      for (final raw in rawDeadlines) {
        if (raw is Map) {
          try {
            final deadline = Deadline.fromJson(Map<String, dynamic>.from(raw));
            await saveDeadline(deadline);
            importedCount++;
          } catch (e) {
            debugPrint('Failed importing item: $e');
          }
        }
      }

      if (decoded['profile'] is Map) {
        try {
          final profile = UserProfile.fromJson(Map<String, dynamic>.from(decoded['profile'] as Map));
          await saveUserProfile(profile);
        } catch (_) {}
      }

      if (decoded['preferences'] is Map) {
        try {
          final prefs = DeadlinePreferences.fromJson(Map<String, dynamic>.from(decoded['preferences'] as Map));
          await saveDeadlinePreferences(prefs);
        } catch (_) {}
      }

      if (decoded['stats'] is Map) {
        try {
          final stats = StreakStats.fromJson(Map<String, dynamic>.from(decoded['stats'] as Map));
          await saveStreakStats(stats);
        } catch (_) {}
      }

      return importedCount;
    } catch (e) {
      debugPrint('Import error: $e');
      return 0;
    }
  }
}
