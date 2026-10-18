import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:flutter/material.dart';

class Greeting extends StatelessWidget {
  const Greeting({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final hour = TimeOfDay.now().hour;
    final greeting = hour < 12
        ? 'goodMorning'
        : hour < 17
        ? 'goodAfternoon'
        : 'goodEvening';
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 4),
        child: Text(
          '${AppStrings.of(context).text(greeting)} $name',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
