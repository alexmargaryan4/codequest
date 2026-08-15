import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around connectivity_plus exposing a simple
/// "is there probably internet" boolean stream.
///
/// This is intentionally conservative: it reports connectivity based on
/// the OS-reported network interface state, not an actual reachability
/// probe. It's used to decide whether it's worth attempting an AI
/// generation call at all, and to explain to the user why only bundled
/// content is available — it is NOT relied upon as a hard guarantee, so
/// AIService's own network error handling still applies even when this
/// reports "online" but the request fails anyway.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isOnline async {
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    return _hasAny(result);
  }

  bool _hasAny(List<ConnectivityResult> result) {
    return result.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }

  Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map(_hasAny);
  }
}

final Provider<ConnectivityService> connectivityServiceProvider =
    Provider<ConnectivityService>((Ref ref) {
  return ConnectivityService();
});

/// Live online/offline status, defaulting to `true` (online) until the
/// first platform check resolves, so the UI doesn't flash an "offline"
/// banner on every cold start.
final StreamProvider<bool> isOnlineProvider = StreamProvider<bool>((Ref ref) async* {
  final ConnectivityService service = ref.watch(connectivityServiceProvider);
  yield await service.isOnline;
  yield* service.onStatusChange;
});
