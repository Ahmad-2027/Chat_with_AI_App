import 'dart:async';

import 'package:chat_app_ai/features/auth/models/app_user.dart';
import 'package:chat_app_ai/features/auth/services/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class AuthState {
  const AuthState();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AppUser user;
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(_initialState(_repository.currentUser)) {
    _authSubscription = _repository.userChanges.listen((user) {
      emit(user == null ? const Unauthenticated() : Authenticated(user));
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _authSubscription;

  static AuthState _initialState(AppUser? user) =>
      user == null ? const Unauthenticated() : Authenticated(user);

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      await _repository.signInWithGoogle();
    } catch (_) {
      emit(const AuthFailure('somethingWentWrong'));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _repository.signOut();
    } catch (_) {
      emit(const AuthFailure('somethingWentWrong'));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
