abstract interface class UserProfileRepository {
  Future<String?> loadName(String userId);
  Future<void> saveName(String userId, String name);
}
