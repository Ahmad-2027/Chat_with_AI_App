import 'package:chat_app_ai/features/auth/services/google_auth_data_source.dart';
import 'package:chat_app_ai/features/auth/models/app_user.dart';
import 'package:chat_app_ai/features/auth/services/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final GoogleAuthDataSource _dataSource;

  @override
  AppUser? get currentUser => _mapUser(_dataSource.currentUser);

  @override
  Stream<AppUser?> get userChanges => _dataSource.userChanges.map(_mapUser);

  @override
  Future<void> signInWithGoogle() => _dataSource.signInWithGoogle();

  @override
  Future<void> signOut() => _dataSource.signOut();

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      name: user.displayName ?? user.email ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }
}
