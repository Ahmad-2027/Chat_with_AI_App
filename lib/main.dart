import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:chat_app_ai/features/auth/services/google_auth_data_source.dart';
import 'package:chat_app_ai/features/auth/services/auth_repository_impl.dart';
import 'package:chat_app_ai/features/auth/services/hive_user_profile_repository.dart';
import 'package:chat_app_ai/features/auth/services/auth_repository.dart';
import 'package:chat_app_ai/features/auth/services/user_profile_repository.dart';
import 'package:chat_app_ai/features/auth/cubit/auth_cubit.dart';
import 'package:chat_app_ai/features/auth/views/pages/auth_gate.dart';
import 'package:chat_app_ai/features/chat/services/hive_chat_repository.dart';
import 'package:chat_app_ai/features/chat/services/chat_repository.dart';
import 'package:chat_app_ai/features/settings/cubit/settings_cubit.dart';
import 'package:chat_app_ai/features/auth/views/widgets/splash_logo.dart';
import 'package:chat_app_ai/core/network/network_status_banner.dart';
import 'package:chat_app_ai/core/network/network_status_cubit.dart';
import 'package:chat_app_ai/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initiallyConnected = await InternetConnection().hasInternetAccess;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  final networkStatusCubit = NetworkStatusCubit(
    initiallyConnected: initiallyConnected,
  );
  final authRepository = AuthRepositoryImpl(
    GoogleAuthDataSource(FirebaseAuth.instance, GoogleSignIn.instance),
  );
  final chatRepository = HiveChatRepository();
  runApp(
    MyApp(
      authRepository: authRepository,
      chatRepository: chatRepository,
      networkStatusCubit: networkStatusCubit,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.authRepository,
    required this.chatRepository,
    required this.networkStatusCubit,
    super.key,
  });

  final AuthRepository authRepository;
  final ChatRepository chatRepository;
  final NetworkStatusCubit networkStatusCubit;

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
        BlocProvider.value(value: networkStatusCubit),
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
          builder: (context, child) =>
              NetworkStatusBanner(child: child ?? const SizedBox.shrink()),
          home: AnimatedSplashScreen(
            duration: 1200,
            splash: const SplashLogo(),
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
