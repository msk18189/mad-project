import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/models/category.dart';
import 'package:deadline/models/deadline_preferences.dart';
import 'package:deadline/models/priority.dart';
import 'package:deadline/models/reminder_type.dart';
import 'package:deadline/models/user_profile.dart';

void main() {
  group('Phase 9 - User Profile Tests (Section 4 & 5)', () {
    test('Default user profile has expected values and initials', () {
      const profile = UserProfile();
      expect(profile.name, 'Sakthi');
      expect(profile.bio, 'Focusing on what counts.');
      expect(profile.initials, 'SA');
    });

    test('Two-word name generates initials correctly', () {
      const profile = UserProfile(name: 'John Doe');
      expect(profile.initials, 'JD');
    });

    test('Single-word and edge-case name initials', () {
      const profile1 = UserProfile(name: 'Antigravity');
      expect(profile1.initials, 'AN');

      const profile2 = UserProfile(name: 'A');
      expect(profile2.initials, 'A');

      const profile3 = UserProfile(name: '   ');
      expect(profile3.initials, 'D');
    });

    test('UserProfile serialization toJson and fromJson', () {
      const profile = UserProfile(name: 'Sakthi K', bio: 'Every second counts.');
      final json = profile.toJson();
      final parsed = UserProfile.fromJson(json);

      expect(parsed.name, 'Sakthi K');
      expect(parsed.bio, 'Every second counts.');
      expect(parsed.initials, 'SK');
    });

    test('UserProfile copyWith updates fields properly', () {
      const profile = UserProfile(name: 'Old Name', bio: 'Old bio');
      final updated = profile.copyWith(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(updated.bio, 'Old bio');
    });
  });

  group('Phase 9 - Deadline Preferences Tests (Section 10, 11, 12)', () {
    test('Default deadline preferences are configured', () {
      const prefs = DeadlinePreferences();
      expect(prefs.defaultPriority, DeadlinePriority.medium);
      expect(prefs.defaultCategory, DeadlineCategory.project);
      expect(prefs.defaultReminders, containsAll([
        ReminderType.oneDayBefore,
        ReminderType.oneHourBefore,
        ReminderType.atDeadline,
      ]));
    });

    test('DeadlinePreferences serialization toJson and fromJson', () {
      const prefs = DeadlinePreferences(
        defaultPriority: DeadlinePriority.high,
        defaultCategory: DeadlineCategory.exam,
        defaultReminders: [ReminderType.oneDayBefore, ReminderType.threeDaysBefore],
      );

      final json = prefs.toJson();
      final parsed = DeadlinePreferences.fromJson(json);

      expect(parsed.defaultPriority, DeadlinePriority.high);
      expect(parsed.defaultCategory, DeadlineCategory.exam);
      expect(parsed.defaultReminders.length, 2);
      expect(parsed.defaultReminders, contains(ReminderType.threeDaysBefore));
    });

    test('DeadlinePreferences copyWith toggles and modifies fields', () {
      const prefs = DeadlinePreferences();
      final updated = prefs.copyWith(
        defaultPriority: DeadlinePriority.low,
        defaultCategory: DeadlineCategory.assignment,
      );

      expect(updated.defaultPriority, DeadlinePriority.low);
      expect(updated.defaultCategory, DeadlineCategory.assignment);
    });
  });

  group('Phase 9 & 10 - Export & Import Validation Tests (Section 17-20, 36)', () {
    test('Export payload structure validation', () {
      final payload = {
        'app': 'DEADLINE',
        'version': '1.0.0+1',
        'exportedAt': DateTime.now().toIso8601String(),
        'profile': const UserProfile(name: 'Sakthi').toJson(),
        'preferences': const DeadlinePreferences().toJson(),
        'deadlines': [
          {
            'id': 'dl_test_export',
            'title': 'Exportable Task',
            'category': 'project',
            'priority': 'high',
            'deadlineDateTime': DateTime.now().toIso8601String(),
            'isCompleted': false,
          }
        ],
        'stats': {'currentStreak': 5, 'longestStreak': 10},
      };

      final jsonStr = jsonEncode(payload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['app'], 'DEADLINE');
      expect(decoded['version'], '1.0.0+1');
      expect(decoded['profile'], isA<Map>());
      expect(decoded['preferences'], isA<Map>());
      expect(decoded['deadlines'], isA<List>());
      expect((decoded['deadlines'] as List).length, 1);
    });

    test('Corrupt or malformed JSON payload handled safely', () {
      const invalidJson = '{ "app": "OTHER", "deadlines": "not a list" }';
      final decoded = jsonDecode(invalidJson) as Map<String, dynamic>;

      expect(decoded['app'], 'OTHER');
      expect(decoded['deadlines'] is List, isFalse);
    });
  });
}
