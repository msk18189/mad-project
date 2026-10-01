import 'package:flutter/foundation.dart';

/// Lightweight local profile identity (Phase 9 Section 4 & 5)
@immutable
class UserProfile {
  final String name;
  final String bio;

  const UserProfile({
    this.name = 'Sakthi',
    this.bio = 'Focusing on what counts.',
  });

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'D';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? bio,
  }) {
    return UserProfile(
      name: name ?? this.name,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bio': bio,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'Sakthi',
      bio: json['bio'] as String? ?? 'Focusing on what counts.',
    );
  }
}
