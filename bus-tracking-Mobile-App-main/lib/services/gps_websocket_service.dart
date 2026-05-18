import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:bus_tracking/utils/constants.dart';

/// Service WebSocket STOMP — diffusion GPS temps réel (Flutter).
///
/// Utilisation :
///   final svc = GpsWebSocketService(
///     busId: 6,
///     onPosition: (data) { setState(() { busPos = data; }); },
///   );
///   svc.connect();
///   // ... plus tard :
///   svc.disconnect();
///
/// Topic STOMP  : /topic/gps/{busId}
/// Endpoint WS  : ws://10.0.2.2:8081/Bus-tracking/ws-native (Android émulateur)
///                ws://localhost:8081/Bus-tracking/ws-native (iOS / web)
class GpsWebSocketService {
  final int busId;
  final void Function(Map<String, dynamic> position) onPosition;
  final void Function()? onConnected;
  final void Function(String error)? onError;

  StompClient? _client;
  bool _disposed = false;

  GpsWebSocketService({
    required this.busId,
    required this.onPosition,
    this.onConnected,
    this.onError,
  });

  /// Établit la connexion WebSocket STOMP et s'abonne au topic du bus.
  void connect() {
    _client = StompClient(
      config: StompConfig(
        url: kWsBackendUrl,
        onConnect: _onConnect,
        onDisconnect: (frame) =>
            debugPrint('[GPS-WS] Déconnecté: ${frame.command}'),
        onWebSocketError: (error) {
          debugPrint('[GPS-WS] Erreur WebSocket: $error');
          onError?.call(error.toString());
        },
        onStompError: (frame) {
          debugPrint('[GPS-WS] Erreur STOMP: ${frame.headers['message']}');
          onError?.call(frame.headers['message'] ?? 'Erreur STOMP inconnue');
        },
        // Reconnexion automatique toutes les 5 secondes si déconnexion
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame connectFrame) {
    debugPrint('[GPS-WS] Connecté ! Abonnement à /topic/gps/$busId');
    onConnected?.call();

    _client!.subscribe(
      destination: '/topic/gps/$busId',
      callback: (StompFrame frame) {
        if (_disposed) return;
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          onPosition(data);
        } catch (e) {
          debugPrint('[GPS-WS] Erreur parse JSON: $e — body: ${frame.body}');
        }
      },
    );
  }

  /// Déconnecte le client STOMP proprement.
  void disconnect() {
    _disposed = true;
    _client?.deactivate();
    _client = null;
  }
}
