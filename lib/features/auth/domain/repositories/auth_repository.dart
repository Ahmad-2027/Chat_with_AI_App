import 'package:chat_app_ai/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> get userChanges;
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
