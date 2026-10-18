import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:chat_app_ai/features/auth/models/app_user.dart';
import 'package:chat_app_ai/features/auth/services/user_profile_repository.dart';
import 'package:chat_app_ai/features/auth/views/pages/welcome_page.dart';
import 'package:chat_app_ai/features/chat/services/firebase_ai_service.dart';
import 'package:chat_app_ai/features/chat/services/chat_repository.dart';
import 'package:chat_app_ai/features/chat/cubit/chat_cubit.dart';
import 'package:chat_app_ai/features/chat/views/pages/chat_history_page.dart';
import 'package:chat_app_ai/features/chat/views/pages/chat_page.dart';
import 'package:chat_app_ai/features/settings/views/pages/settings_page.dart';
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

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  int _selectedIndex = 0;
  bool _isProfileReady = false;
  bool _showWelcome = false;
  String _displayName = '';
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  String _welcomeKey(String userId) => 'welcome_completed_$userId';

  @override
  Widget build(BuildContext context) {
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
}
