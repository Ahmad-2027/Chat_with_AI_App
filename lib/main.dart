import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:chat_app_ai/features/auth/data/datasources/google_auth_data_source.dart';
import 'package:chat_app_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_app_ai/features/auth/data/repositories/hive_user_profile_repository.dart';
import 'package:chat_app_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:chat_app_ai/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:chat_app_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chat_app_ai/features/auth/presentation/pages/auth_gate.dart';
import 'package:chat_app_ai/features/chat/data/repositories/hive_chat_repository.dart';
import 'package:chat_app_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app_ai/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:chat_app_ai/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  final authRepository = AuthRepositoryImpl(
    GoogleAuthDataSource(FirebaseAuth.instance, GoogleSignIn.instance),
  );
  final chatRepository = HiveChatRepository();
  runApp(MyApp(authRepository: authRepository, chatRepository: chatRepository));
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.authRepository,
    required this.chatRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final ChatRepository chatRepository;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: authRepository),
      RepositoryProvider<UserProfileRepository>(
        create: (_) => HiveUserProfileRepository(),
      ),
      RepositoryProvider<ChatRepository>.value(value: chatRepository),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(context.read<AuthRepository>()),
        ),
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Aura',
          themeMode: settings.themeMode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          locale: settings.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AnimatedSplashScreen(
            duration: 1200,
            splash: const _SplashLogo(),
            nextScreen: const AuthGate(),
            splashTransition: SplashTransition.fadeTransition,
            backgroundColor: const Color(0xFF7057E8),
            splashIconSize: 170,
          ),
        ),
      ),
    ),
  );

  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7057E8),
      brightness: brightness,
    ),
  );
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 74),
      SizedBox(height: 12),
      Text(
        'aura',
        style: TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}
