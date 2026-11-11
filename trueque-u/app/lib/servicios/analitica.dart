import 'package:flutter/foundation.dart';

import 'cliente_api.dart';

Future<void> track(
  String evento,
  Map<String, dynamic> props,
  ClienteApi api,
) async {
  final registro = {
    'evento': evento,
    'props': props,
    'fecha': DateTime.now().toIso8601String(),
  };
  debugPrint('[$evento] $props');
  try {
    await api.post('/eventos', registro);
  } catch (_) {}
}
