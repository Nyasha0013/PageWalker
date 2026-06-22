import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>.broadcast();
  final connectivity = Connectivity();

  Future<void> emit() async {
    final results = await connectivity.checkConnectivity();
    controller.add(_hasNetwork(results));
  }

  final sub = connectivity.onConnectivityChanged.listen((results) {
    controller.add(_hasNetwork(results));
  });

  emit();
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

bool _hasNetwork(List<ConnectivityResult> results) {
  return results.any(
    (r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn,
  );
}
