import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkStatus {
  const NetworkStatus({
    required this.hasInternetAccess,
    this.isChecking = false,
  });

  final bool hasInternetAccess;
  final bool isChecking;
}

class NetworkStatusCubit extends Cubit<NetworkStatus> {
  NetworkStatusCubit({required bool initiallyConnected})
    : _connection = InternetConnection(),
      super(NetworkStatus(hasInternetAccess: initiallyConnected)) {
    _statusSubscription = _connection.onStatusChange.listen(_updateStatus);
  }

  final InternetConnection _connection;
  late final StreamSubscription<InternetStatus> _statusSubscription;
  int _checkId = 0;

  Future<void> checkConnection() async {
    final checkId = ++_checkId;
    emit(
      NetworkStatus(
        hasInternetAccess: state.hasInternetAccess,
        isChecking: true,
      ),
    );
    final hasInternetAccess = await _connection.hasInternetAccess;
    if (isClosed || checkId != _checkId) return;
    emit(NetworkStatus(hasInternetAccess: hasInternetAccess));
  }

  void _updateStatus(InternetStatus status) {
    _checkId++;
    emit(NetworkStatus(hasInternetAccess: status == InternetStatus.connected));
  }

  @override
  Future<void> close() async {
    await _statusSubscription.cancel();
    return super.close();
  }
}
