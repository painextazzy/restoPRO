// lib/services/websocket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  late IO.Socket socket;
  bool _isConnected = false;

  void connect(String serverUrl) {
    if (_isConnected) return;
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    socket.onConnect((_) {
      _isConnected = true;
      print('🟢 WebSocket connecté');
    });
    socket.onDisconnect((_) {
      _isConnected = false;
      print('🔴 WebSocket déconnecté');
    });
    socket.onError((data) {
      print('❌ WebSocket erreur : $data');
    });
    socket.connect();
  }

  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
      socket.dispose();
      _isConnected = false;
    }
  }

  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }
}
