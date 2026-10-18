import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:chat_app_ai/features/auth/models/app_user.dart';
import 'package:chat_app_ai/features/auth/services/user_profile_repository.dart';
import 'package:chat_app_ai/features/auth/cubit/auth_cubit.dart';
import 'package:chat_app_ai/features/settings/cubit/settings_cubit.dart';
import 'package:chat_app_ai/features/settings/views/widgets/settings_section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.user,
    required this.displayName,
    required this.onNameChanged,
    super.key,
  });

  final AppUser user;
  final String displayName;
  final ValueChanged<String> onNameChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameController;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.text('settingsTitle'))),
        body: BlocBuilder<SettingsCubit, SettingsState>(
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
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.text('profileSaveError')}: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }
}
