import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:chat_app_ai/core/network/network_status_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<NetworkStatusCubit, NetworkStatus>(
    builder: (context, state) {
      if (state.hasInternetAccess) return child;
      final strings = AppStrings.of(context);
      final colorScheme = Theme.of(context).colorScheme;
      return Column(
        children: [
          Material(
            color: colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 16,
                  end: 8,
                  top: 8,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.text('noInternetConnection'),
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: state.isChecking
                          ? null
                          : context.read<NetworkStatusCubit>().checkConnection,
                      child: state.isChecking
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onErrorContainer,
                              ),
                            )
                          : Text(strings.text('retry')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      );
    },
  );
}
