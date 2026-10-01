import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/deadline.dart';
import '../../models/deadline_reminder.dart';

abstract class ILocalDatabaseService {
  Future<void> init();
  Future<List<Deadline>> getAllDeadlines();
  Future<Deadline?> getDeadlineById(String id);
  Future<void> insertDeadline(Deadline deadline);
  Future<void> updateDeadline(Deadline deadline);
  Future<void> deleteDeadline(String id);
  Future<void> clearAll();

  // Reminder persistence (Phase 4)
  Future<List<DeadlineReminder>> getAllReminders() async => [];
  Future<List<DeadlineReminder>> getRemindersForDeadline(String deadlineId) async => [];
  Future<void> saveReminder(DeadlineReminder reminder) async {}
  Future<void> deleteReminder(String id) async {}
  Future<void> deleteRemindersForDeadline(String deadlineId) async {}
  Future<bool> getGlobalNotificationsEnabled() async => true;
  Future<void> setGlobalNotificationsEnabled(bool enabled) async {}
  Future<Set<ReminderType>> getDefaultReminderPreferences() async => ReminderType.values.toSet();
  Future<void> setDefaultReminderPreferences(Set<ReminderType> types) async {}
}

/// Hive-backed production implementation of ILocalDatabaseService
class LocalDatabaseService implements ILocalDatabaseService {
  static const String _boxName = 'deadlines_vault_v2';
  static const String _legacyBoxName = 'deadlines_box_v1';
  static const String _remindersBoxName = 'reminders_vault_v1';
  static const String _settingsBoxName = 'deadline_settings_v1';

  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Box<String>? _box;
  Box<String>? _remindersBox;
  Box<dynamic>? _settingsBox;
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized && _box != null && _box!.isOpen) return;

    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      _remindersBox = await Hive.openBox<String>(_remindersBoxName);
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

      // Check and migrate legacy records if existing
      if (await Hive.boxExists(_legacyBoxName)) {
        final legacyBox = await Hive.openBox<String>(_legacyBoxName);
        if (legacyBox.isNotEmpty && _box!.isEmpty) {
          for (final key in legacyBox.keys) {
            final val = legacyBox.get(key);
            if (val != null) {
              await _box!.put(key.toString(), val);
            }
          }
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalDatabaseService initialization warning: $e');
    }
  }

  Box<String> get _safeBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('Database not initialized. Ensure init() is awaited.');
    }
    return _box!;
  }

  Box<String> get _safeRemindersBox {
    if (_remindersBox == null || !_remindersBox!.isOpen) {
      throw StateError('Reminders box not initialized. Ensure init() is awaited.');
    }
    return _remindersBox!;
  }

  Box<dynamic> get _safeSettingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw StateError('Settings box not initialized. Ensure init() is awaited.');
    }
    return _settingsBox!;
  }

  @override
  Future<List<Deadline>> getAllDeadlines() async {
    if (!_isInitialized) await init();
    final list = <Deadline>[];
    for (final rawJson in _safeBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
        list.add(Deadline.fromJson(map));
      } catch (e) {
        debugPrint('Error deserializing deadline record: $e');
      }
    }
    return list;
  }

  @override
  Future<Deadline?> getDeadlineById(String id) async {
    if (!_isInitialized) await init();
    final rawJson = _safeBox.get(id);
    if (rawJson == null) return null;

    try {
      final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
      return Deadline.fromJson(map);
    } catch (e) {
      debugPrint('Error deserializing deadline by id: $e');
      return null;
    }
  }

  @override
  Future<void> insertDeadline(Deadline deadline) async {
    if (!_isInitialized) await init();
    final raw = jsonEncode(deadline.toJson());
    await _safeBox.put(deadline.id, raw);
  }

  @override
  Future<void> updateDeadline(Deadline deadline) async {
    if (!_isInitialized) await init();
    final raw = jsonEncode(deadline.toJson());
    await _safeBox.put(deadline.id, raw);
  }

  @override
  Future<void> deleteDeadline(String id) async {
    if (!_isInitialized) await init();
    await _safeBox.delete(id);
  }

  @override
  Future<void> clearAll() async {
    if (!_isInitialized) await init();
    await _safeBox.clear();
    await _safeRemindersBox.clear();
  }

  // --- REMINDERS PERSISTENCE (Section 28 & 57) ---

  @override
  Future<List<DeadlineReminder>> getAllReminders() async {
    if (!_isInitialized) await init();
    final list = <DeadlineReminder>[];
    for (final raw in _safeRemindersBox.values) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        list.add(DeadlineReminder.fromJson(map));
      } catch (e) {
        debugPrint('Error deserializing reminder: $e');
      }
    }
    return list;
  }

  @override
  Future<List<DeadlineReminder>> getRemindersForDeadline(String deadlineId) async {
    final all = await getAllReminders();
    return all.where((r) => r.deadlineId == deadlineId).toList();
  }

  @override
  Future<void> saveReminder(DeadlineReminder reminder) async {
    if (!_isInitialized) await init();
    final raw = jsonEncode(reminder.toJson());
    await _safeRemindersBox.put(reminder.id, raw);
  }

  @override
  Future<void> deleteReminder(String id) async {
    if (!_isInitialized) await init();
    await _safeRemindersBox.delete(id);
  }

  @override
  Future<void> deleteRemindersForDeadline(String deadlineId) async {
    if (!_isInitialized) await init();
    final toDelete = <String>[];
    for (final key in _safeRemindersBox.keys) {
      final raw = _safeRemindersBox.get(key);
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['deadlineId'] == deadlineId) {
            toDelete.add(key.toString());
          }
        } catch (_) {}
      }
    }
    for (final key in toDelete) {
      await _safeRemindersBox.delete(key);
    }
  }

  // --- SETTINGS PERSISTENCE (Section 24 & 26) ---

  @override
  Future<bool> getGlobalNotificationsEnabled() async {
    if (!_isInitialized) await init();
    return _safeSettingsBox.get('notifications_enabled', defaultValue: true) as bool;
  }

  @override
  Future<void> setGlobalNotificationsEnabled(bool enabled) async {
    if (!_isInitialized) await init();
    await _safeSettingsBox.put('notifications_enabled', enabled);
  }

  @override
  Future<Set<ReminderType>> getDefaultReminderPreferences() async {
    if (!_isInitialized) await init();
    final rawList = _safeSettingsBox.get('default_reminders') as List<dynamic>?;
    if (rawList == null) {
      return ReminderType.values.toSet();
    }
    return rawList.map((e) => ReminderType.fromString(e.toString())).toSet();
  }

  @override
  Future<void> setDefaultReminderPreferences(Set<ReminderType> types) async {
    if (!_isInitialized) await init();
    final names = types.map((e) => e.name).toList();
    await _safeSettingsBox.put('default_reminders', names);
  }
}
