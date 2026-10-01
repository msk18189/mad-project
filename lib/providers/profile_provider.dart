import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/storage_service.dart';
import '../models/user_profile.dart';

export '../models/user_profile.dart';

class UserProfileNotifier extends Notifier<UserProfile> {
  late final StorageService _storage;

  @override
  UserProfile build() {
    _storage = StorageService();
    return _storage.getUserProfile();
  }

  Future<void> updateProfile({required String name, String? bio}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final updated = state.copyWith(
      name: trimmedName,
      bio: bio?.trim(),
    );
    state = updated;
    await _storage.saveUserProfile(updated);
  }
}

final profileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
