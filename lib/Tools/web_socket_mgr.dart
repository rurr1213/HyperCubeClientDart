import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

//import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; // Import the correct channel
import 'logger.dart';

// Assuming you have a Logger class. Replace with your actual logging mechanism
/*
class Logger {
  void add(EVENTTYPE type, String from, String msg) {
    print("$type, $from, $msg");
  }
}

enum EVENTTYPE { INFO, WARNING, ERROR }
*/

class SecureWebSocketClient {
  final String _serverUrl;
  final Logger _logger;
//  IOWebSocketChannel? _channel;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  StreamSubscription? _subscription;

  // Callbacks
  Function()? onConnectCallback;
  Function(dynamic)? onMessageCallback;
  Function()? onDisconnectCallback;
  Function(dynamic)? onErrorCallback;

  SecureWebSocketClient(this._serverUrl, this._logger);

  Future<bool> connect() async {
    try {
      // Construct the URL with wss:// to enforce a secure connection
      final url = _serverUrl.startsWith('ws://')
          ? _serverUrl.replaceFirst('ws://', 'wss://')
          : _serverUrl;

      _channel =
          WebSocketChannel.connect(Uri.parse(url)); // Use WebSocketChannel

      _subscription = _channel!.stream.listen(
        (message) {
          _logger.add(EVENTTYPE.INFO, "WebSocket", "Received: $message");
          onMessageCallback?.call(message);
        },
        onDone: () {
          _logger.add(EVENTTYPE.INFO, "WebSocket", 'Connection closed');
          _isConnected = false;
          _subscription = null; // Prevent potential memory leaks
          _channel = null; // Prevent potential issues on reconnect attempts
          onDisconnectCallback?.call();
        },
        onError: (error) {
          _logger.add(EVENTTYPE.ERROR, "WebSocket", 'Error: $error');
          _isConnected = false;
          _subscription = null; // Prevent potential memory leaks
          _channel = null; // Prevent potential issues on reconnect attempts

          onErrorCallback?.call(error);
        },
      );

      _isConnected = true;
      _logger.add(EVENTTYPE.INFO, "WebSocket", "Connected ");

      onConnectCallback?.call();
      return true;
    } catch (e) {
      _logger.add(EVENTTYPE.ERROR, "WebSocket", "Connection failed: $e");
      _isConnected = false;

      onErrorCallback?.call(e); // Notify of the connection error
      return false;
    }
  }

  void send(dynamic data) {
    if (_isConnected && _channel != null) {
      try {
        if (data is String) {
          _channel!.sink.add(data);
          _logger.add(EVENTTYPE.INFO, "WebSocket", "Sent string: $data");
        } else if (data is Uint8List) {
          _channel!.sink.add(data); // Send binary data directly
          _logger.add(EVENTTYPE.INFO, "WebSocket",
              "Sent binary data (length: ${data.length})");
        } else {
          final jsonData = jsonEncode(data);
          _channel!.sink.add(jsonData);
          _logger.add(EVENTTYPE.INFO, "WebSocket", "Sent JSON: $jsonData");
        }
      } catch (e) {
        _logger.add(EVENTTYPE.ERROR, "WebSocket", "Send error: $e");
        onErrorCallback?.call(e);
      }
    } else {
      _logger.add(
          EVENTTYPE.WARNING, "WebSocket", "Not connected, cannot send data");
    }
  }

  Future<void> disconnect() async {
    if (_isConnected && _channel != null) {
      await _subscription
          ?.cancel(); // Ensure stream subscription is cancelled first
      await _channel!.sink.close();
      _isConnected = false;
      _channel = null; // Release the channel resources
    }
  }

  bool get isConnected => _isConnected;
}
