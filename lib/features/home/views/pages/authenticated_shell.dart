import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:chat_app_ai/features/auth/models/app_user.dart';
import 'package:chat_app_ai/features/auth/cubit/auth_cubit.dart';
import 'package:chat_app_ai/features/auth/services/user_profile_repository.dart';
import 'package:chat_app_ai/features/auth/views/pages/welcome_page.dart';
import 'package:chat_app_ai/features/chat/services/firebase_ai_service.dart';
import 'package:chat_app_ai/features/chat/services/chat_repository.dart';
import 'package:chat_app_ai/features/chat/cubit/chat_cubit.dart';
import 'package:chat_app_ai/features/chat/views/pages/chat_history_page.dart';
import 'package:chat_app_ai/features/chat/views/pages/chat_page.dart';
import 'package:chat_app_ai/features/settings/views/pages/settings_page.dart';
import 'package:chat_app_ai/features/settings/services/app_lock_service.dart';
import 'package:chat_app_ai/features/home/views/widgets/greeting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({required this.user, super.key});

  final AppUser user;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isProfileReady = false;
  bool _showWelcome = false;
  bool _isAppLockReady = false;
  bool _isAppLocked = true;
  bool _isUnlocking = false;
  int _lockGeneration = 0;
  String _displayName = '';
  String? _profileError;
  String? _appLockError;
  String? _unlockError;
  AppLockSettings? _appLockSettings;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _passwordController = TextEditingController();
    _loadProfile();
    _loadAppLockSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        _appLockSettings?.passwordEnabled == true) {
      _lockGeneration++;
      setState(() {
        _isAppLocked = true;
        _unlockError = null;
        _passwordController.clear();
      });
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profileRepository = context.read<UserProfileRepository>();
      final preferences = await SharedPreferences.getInstance();
      final savedName = await profileRepository.loadName(widget.user.id);
      final welcomeShown =
          preferences.getBool(_welcomeKey(widget.user.id)) ?? false;
      if (!mounted) return;
      setState(() {
        _displayName = savedName ?? widget.user.name;
        _showWelcome = !welcomeShown;
        _isProfileReady = true;
        _profileError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileError = 'somethingWentWrong';
        _isProfileReady = true;
      });
    }
  }

  Future<void> _completeWelcome(String name) async {
    try {
      await context.read<UserProfileRepository>().saveName(
        widget.user.id,
        name,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_welcomeKey(widget.user.id), true);
      if (!mounted) return;
      setState(() {
        _displayName = name;
        _showWelcome = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).text('somethingWentWrong')),
        ),
      );
    }
  }

  void _updateName(String name) {
    setState(() => _displayName = name);
  }

  void _onAppLockSettingsChanged(AppLockSettings settings) {
    setState(() {
      final wasPasswordEnabled = _appLockSettings?.passwordEnabled == true;
      _appLockSettings = settings;
      if (settings.passwordEnabled && !wasPasswordEnabled) {
        _isAppLocked = true;
        _passwordController.clear();
      } else if (!settings.passwordEnabled) {
        _isAppLocked = false;
      }
    });
  }

  String _welcomeKey(String userId) => 'welcome_completed_$userId';

  @override
  Widget build(BuildContext context) {
    if (!_isAppLockReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_appLockError != null) {
      return _buildAppLockError(context);
    }
    final isLocked = _appLockSettings?.passwordEnabled == true && _isAppLocked;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: isLocked,
          child: ExcludeSemantics(
            excluding: isLocked,
            child: _buildAuthenticatedPage(context),
          ),
          
        ),
        if (isLocked) _buildAppLockScreen(context),
      ],
    );
  }

  Widget _buildAuthenticatedPage(BuildContext context) {
    if (!_isProfileReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_profileError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.of(context).text(_profileError!),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _isProfileReady = false;
                      _profileError = null;
                    });
                    _loadProfile();
                  },
                  child: Text(AppStrings.of(context).text('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_showWelcome) {
      final initialName = widget.user.name == widget.user.email
          ? ''
          : widget.user.name;
      return WelcomePage(
        initialName: initialName,
        onContinue: _completeWelcome,
      );
    }
    return BlocProvider(
      create: (context) => ChatCubit(
        context.read<ChatRepository>(),
        FirebaseAiService(),
        widget.user.id,
      )..loadHistory(),
      child: Builder(
        builder: (context) {
          final strings = AppStrings.of(context);
          final pageTitle = _selectedIndex == 0
              ? strings.text('home')
              : strings.text('history');
          return Scaffold(
            appBar: AppBar(
              title: Text(pageTitle),
              actions: [
                if (_selectedIndex == 0)
                  IconButton(
                    tooltip: strings.text('newChat'),
                    onPressed: context.read<ChatCubit>().startNewChat,
                    icon: const Icon(Icons.edit_square),
                  ),
                IconButton(
                  tooltip: strings.text('settings'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsPage(
                        user: widget.user,
                        displayName: _displayName,
                        onNameChanged: _updateName,
                        onAppLockSettingsChanged: _onAppLockSettingsChanged,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 6),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                Column(
                  children: [
                    Greeting(name: _displayName),
                    const Expanded(child: ChatPage()),
                  ],
                ),
                ChatHistoryPage(
                  onChatSelected: (chatId) {
                    context.read<ChatCubit>().loadChat(chatId);
                    setState(() => _selectedIndex = 0);
                  },
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
                if (index == 1) context.read<ChatCubit>().loadHistory();
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: const Icon(Icons.chat_rounded),
                  label: strings.text('home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_rounded),
                  label: strings.text('history'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppLockScreen(BuildContext context) {
    final strings = AppStrings.of(context);
    final showBiometricUnlock =
        _appLockSettings?.biometricsEnabled == true &&
        _appLockSettings?.biometricsAvailable == true;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    strings.text('appLocked'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.text('enterAppPassword'),
                    textAlign: TextAlign.center,
                  ),
                  if (showBiometricUnlock) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _isUnlocking ? null : _unlockWithBiometrics,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: Text(strings.text('unlockWithBiometrics')),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: strings.text('appPassword'),
                      border: const OutlineInputBorder(),
                      errorText: _unlockError == null
                          ? null
                          : strings.text(_unlockError!),
                    ),
                    onSubmitted: (_) => _unlockWithPassword(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isUnlocking ? null : _unlockWithPassword,
                    child: _isUnlocking
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(strings.text('unlock')),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<AuthCubit>().signOut(),
                    child: Text(strings.text('logout')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLockError(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.text(_appLockError!), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _appLockError = null;
                    _isAppLockReady = false;
                  });
                  _loadAppLockSettings();
                },
                child: Text(strings.text('retry')),
              ),
              TextButton(
                onPressed: () => context.read<AuthCubit>().signOut(),
                child: Text(strings.text('logout')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAppLockSettings() async {
    try {
      final settings = await context.read<AppLockService>().loadSettings(
        widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        _appLockSettings = settings;
        _isAppLocked = settings.passwordEnabled;
        _isAppLockReady = true;
        _appLockError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAppLockReady = true;
        _appLockError = 'somethingWentWrong';
      });
    }
  }

  Future<void> _unlockWithPassword() async {
    final lockGeneration = _lockGeneration;
    setState(() {
      _isUnlocking = true;
      _unlockError = null;
    });
    try {
      final authenticated = await context.read<AppLockService>().verifyPassword(
        widget.user.id,
        _passwordController.text,
      );
      if (!mounted) return;
      if (lockGeneration != _lockGeneration) return;
      if (authenticated) {
        setState(() {
          _isAppLocked = false;
          _passwordController.clear();
        });
      } else {
        setState(() => _unlockError = 'incorrectPassword');
      }
    } catch (_) {
      if (mounted) setState(() => _unlockError = 'somethingWentWrong');
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }

  Future<void> _unlockWithBiometrics() async {
    final lockGeneration = _lockGeneration;
    setState(() {
      _isUnlocking = true;
      _unlockError = null;
    });
    try {
      final authenticated = await context
          .read<AppLockService>()
          .authenticateWithBiometrics(
            AppStrings.of(context).text('biometricUnlockReason'),
          );
      if (!mounted) return;
      if (lockGeneration != _lockGeneration) return;
      if (authenticated) {
        setState(() => _isAppLocked = false);
      } else {
        setState(() => _unlockError = 'authenticationFailed');
      }
    } catch (_) {
      if (mounted) setState(() => _unlockError = 'authenticationFailed');
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }
}
