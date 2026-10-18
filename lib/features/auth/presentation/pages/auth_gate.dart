import 'package:chat_app_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chat_app_ai/features/auth/presentation/pages/sign_in_page.dart';
import 'package:chat_app_ai/features/home/presentation/pages/authenticated_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      if (state is Authenticated) {
        return AuthenticatedShell(
          key: ValueKey(state.user.id),
          user: state.user,
        );
      }
      if (state is Unauthenticated ||
          state is AuthFailure ||
          state is AuthLoading) {
        return const SignInPage();
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    },
  );
}
