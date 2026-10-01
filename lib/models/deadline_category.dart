import 'package:flutter/material.dart';

enum DeadlineCategory {
  assignment,
  exam,
  project,
  hackathon,
  application,
  event,
  other;

  DeadlineCategoryConfig get config => DeadlineCategoryConfig.from(this);
  String get displayName => config.displayName;
  String get label => config.displayName;
  String get emoji => config.emoji;
  IconData get icon => config.icon;
  Color get color => config.color;

  static DeadlineCategory fromString(String? val) {
    if (val == null) return DeadlineCategory.other;
    return DeadlineCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() ||
          DeadlineCategoryConfig.from(e).displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => DeadlineCategory.other,
    );
  }
}

class DeadlineCategoryConfig {
  final DeadlineCategory category;
  final String displayName;
  final String emoji;
  final IconData icon;
  final Color color;
  final String description;

  const DeadlineCategoryConfig({
    required this.category,
    required this.displayName,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.description,
  });

  static DeadlineCategoryConfig from(DeadlineCategory category) {
    switch (category) {
      case DeadlineCategory.assignment:
        return const DeadlineCategoryConfig(
          category: DeadlineCategory.assignment,
          displayName: 'Assignment',
          emoji: '📚',
          icon: Icons.menu_book_rounded,
          color: Color(0xFF4A7C59),
          description: 'Coursework, homework, and problem sets.',
        );
      case DeadlineCategory.exam:
        return const DeadlineCategoryConfig(
          category: DeadlineCategory.exam,
          displayName: 'Exam',
          emoji: '📝',
          icon: Icons.edit_note_rounded,
          color: Color(0xFFC05621),
          description: 'Midterms, finals, quizzes, and tests.',
        );
      case DeadlineCategory.project:
        return const DeadlineCategoryConfig(
          category: DeadlineCategory.project,
          displayName: 'Project',
          emoji: '💻',
          icon: Icons.code_rounded,
          color: Color(0xFF2B6CB0),
          description: 'Software builds, design deliveries, and capstones.',
        );
      case DeadlineCategory.hackathon:
        return const DeadlineCategoryConfig(
          category: DeadlineCategory.hackathon,
          displayName: 'Hackathon',
          emoji: '🏆',
          icon: Icons.emoji_events_rounded,
          color: Color(0xFF805AD5),
          description: 'Sprint-based competitions and prototype challenges.',
        );
      case DeadlineCategory.application:
        return const DeadlineCategoryConfig(
          category: DeadlineCategory.application,
          displayName: 'Application',
          emoji: '🎯',
          icon: Icons.ads_click_rounded,
          color: Color(0xFFDD6B20),
          description: 'Jobs, internships, grants, and admissions.',
        );
      case DeadlineCategory.event:
        return const DeadlineCategoryConfig(
          category: DeadlineCategory.event,
          displayName: 'Event',
          emoji: '🎉',
          icon: Icons.celebration_rounded,
          color: Color(0xFFD53F8C),
          description: 'Conferences, workshops, and milestones.',
        );
      case DeadlineCategory.other:
        return const DeadlineCategoryConfig(
          category: DeadlineCategory.other,
          displayName: 'Other',
          emoji: '📌',
          icon: Icons.push_pin_rounded,
          color: Color(0xFF718096),
          description: 'Miscellaneous deadlines and tasks.',
        );
    }
  }
}
