import 'package:chat_app_ai/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:hive_ce/hive.dart';

class HiveUserProfileRepository implements UserProfileRepository {
  static const _boxName = 'user_profiles';

  Future<Box<dynamic>> get _profiles => Hive.openBox<dynamic>(_boxName);

  @override
  Future<String?> loadName(String userId) async {
    final profiles = await _profiles;
    return profiles.get(userId) as String?;
  }

  @override
  Future<void> saveName(String userId, String name) async {
    final normalizedName = name.trim();
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty.');
    }
    final profiles = await _profiles;
    await profiles.put(userId, normalizedName);
  }
}
