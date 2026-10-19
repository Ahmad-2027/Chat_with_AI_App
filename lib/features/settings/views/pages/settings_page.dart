import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:chat_app_ai/features/auth/models/app_user.dart';
import 'package:chat_app_ai/features/auth/services/user_profile_repository.dart';
import 'package:chat_app_ai/features/auth/cubit/auth_cubit.dart';
import 'package:chat_app_ai/features/settings/cubit/settings_cubit.dart';
import 'package:chat_app_ai/features/settings/services/app_lock_service.dart';
import 'package:chat_app_ai/features/settings/views/widgets/settings_section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.user,
    required this.displayName,
    required this.onNameChanged,
    required this.onAppLockSettingsChanged,
    super.key,
  });

  final AppUser user;
  final String displayName;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<AppLockSettings> onAppLockSettingsChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameController;
  bool _isSavingName = false;
  AppLockSettings? _appLockSettings;
  bool _isLoadingAppLock = true;
  bool _isUpdatingAppLock = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);
    _loadAppLockSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(strings.text(state.message))));
        } else if (state is AuthSignOutFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(strings.text(state.message))));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.text('settingsTitle'))),
        body: SafeArea(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SettingsSectionTitle(title: strings.text('appearance')),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: Text(strings.text('darkMode')),
                    value: state.themeMode == ThemeMode.dark,
                    onChanged: context.read<SettingsCubit>().setDarkMode,
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSectionTitle(title: strings.text('language')),
                Card(
                  child: RadioGroup<String>(
                    groupValue: state.locale.languageCode,
                    onChanged: (language) {
                      if (language != null) {
                        context.read<SettingsCubit>().setLanguage(language);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'en',
                          title: Text(strings.text('english')),
                          secondary: const Icon(Icons.language_rounded),
                        ),
                        RadioListTile<String>(
                          value: 'ar',
                          title: Text(strings.text('arabic')),
                          secondary: const Icon(Icons.translate_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSectionTitle(title: strings.text('security')),
                Card(
                  child: Column(
                    children: [
                      if (_isLoadingAppLock)
                        const ListTile(
                          leading: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_appLockSettings == null)
                        ListTile(
                          title: Text(strings.text('somethingWentWrong')),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() => _isLoadingAppLock = true);
                              _loadAppLockSettings();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        )
                      else ...[
                        SwitchListTile(
                          secondary: const Icon(Icons.lock_outline_rounded),
                          title: Text(strings.text('appPasswordLock')),
                          subtitle: Text(
                            strings.text(
                              _appLockSettings!.passwordEnabled
                                  ? 'appPasswordEnabled'
                                  : 'appPasswordDescription',
                            ),
                          ),
                          value: _appLockSettings!.passwordEnabled,
                          onChanged: _isUpdatingAppLock
                              ? null
                              : _setPasswordLockEnabled,
                        ),
                        if (_appLockSettings!.passwordEnabled &&
                            (_appLockSettings!.biometricsAvailable ||
                                _appLockSettings!.biometricsEnabled))
                          SwitchListTile(
                            secondary: const Icon(Icons.fingerprint_rounded),
                            title: Text(strings.text('biometricUnlock')),
                            subtitle: Text(
                              strings.text(
                                _appLockSettings!.biometricsAvailable
                                    ? 'biometricUnlockDescription'
                                    : 'biometricUnavailable',
                              ),
                            ),
                            value: _appLockSettings!.biometricsEnabled,
                            onChanged:
                                _isUpdatingAppLock ||
                                    (!_appLockSettings!.biometricsAvailable &&
                                        !_appLockSettings!.biometricsEnabled)
                                ? null
                                : _setBiometricsEnabled,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SettingsSectionTitle(title: strings.text('account')),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.text('profile'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          strings.text('email'),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(widget.user.email),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: strings.text('yourName'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          onSubmitted: (_) => _saveName(),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _isSavingName ? null : _saveName,
                          child: _isSavingName
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(strings.text('saveName')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: Text(strings.text('logout')),
                    onTap: () => context.read<AuthCubit>().signOut(),
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    strings.text(state.error!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    final strings = AppStrings.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.text('nameRequired'))));
      return;
    }
    setState(() => _isSavingName = true);
    try {
      await context.read<UserProfileRepository>().saveName(
        widget.user.id,
        name,
      );
      widget.onNameChanged(name);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.text('nameSaved'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.text('somethingWentWrong'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _loadAppLockSettings() async {
    try {
      final settings = await context.read<AppLockService>().loadSettings(
        widget.user.id,
      );
      if (mounted) {
        setState(() {
          _appLockSettings = settings;
          _isLoadingAppLock = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAppLock = false);
        _showAppLockError();
      }
    }
  }

  Future<void> _setPasswordLockEnabled(bool enabled) async {
    final appLockService = context.read<AppLockService>();
    if (!enabled) {
      await _updateAppLock(() async {
        await appLockService.clearForUser(widget.user.id);
        _appLockSettings = const AppLockSettings(
          passwordEnabled: false,
          biometricsEnabled: false,
          biometricsAvailable: false,
        );
      });
      return;
    }

    final password = await _showSetPasswordDialog();
    if (password == null) return;
    if (!mounted) return;
    await _updateAppLock(() async {
      await appLockService.setPassword(widget.user.id, password);
      _appLockSettings = await appLockService.loadSettings(widget.user.id);
    });
  }

  Future<void> _setBiometricsEnabled(bool enabled) async {
    final strings = AppStrings.of(context);
    final appLockService = context.read<AppLockService>();
    await _updateAppLock(() async {
      if (enabled) {
        final authenticated = await appLockService.authenticateWithBiometrics(
          strings.text('biometricUnlockReason'),
        );
        if (!authenticated) {
          throw _BiometricAuthenticationCancelled();
        }
      }
      await appLockService.setBiometricsEnabled(widget.user.id, enabled);
      _appLockSettings = await appLockService.loadSettings(widget.user.id);
    }, showCancelledMessage: false);
  }

  Future<void> _updateAppLock(
    Future<void> Function() update, {
    bool showCancelledMessage = true,
  }) async {
    setState(() => _isUpdatingAppLock = true);
    try {
      await update();
      if (mounted) {
        setState(() {});
        final settings = _appLockSettings;
        if (settings != null) widget.onAppLockSettingsChanged(settings);
      }
    } on _BiometricAuthenticationCancelled {
      if (showCancelledMessage) _showAppLockError();
    } catch (_) {
      _showAppLockError();
    } finally {
      if (mounted) setState(() => _isUpdatingAppLock = false);
    }
  }

  Future<String?> _showSetPasswordDialog() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _SetPasswordDialog(),
    );
  }

  void _showAppLockError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).text('somethingWentWrong')),
      ),
    );
  }
}

class _BiometricAuthenticationCancelled implements Exception {}

class _SetPasswordDialog extends StatefulWidget {
  const _SetPasswordDialog();

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _validationError;
  bool _closing = false;

  void _submit() {
    if (_closing) return;

    final password = _passwordController.text;
    final confirmation = _confirmController.text;

    if (password.length < 4) {
      setState(() => _validationError = 'passwordTooShort');
      return;
    }

    if (password != confirmation) {
      setState(() => _validationError = 'passwordsDoNotMatch');
      return;
    }

    _closing = true;
    Navigator.of(context).pop(password);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AlertDialog(
      title: Text(strings.text('setAppPassword')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: strings.text('appPassword')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: strings.text('confirmAppPassword'),
              errorText: _validationError == null
                  ? null
                  : strings.text(_validationError!),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_closing) return;
            _closing = true;
            Navigator.of(context).pop();
          },
          child: Text(strings.text('cancel')),
        ),
        FilledButton(onPressed: _submit, child: Text(strings.text('save'))),
      ],
    );
  }
}
