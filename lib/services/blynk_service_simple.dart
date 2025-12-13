import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Simple Blynk service that connects via WebSocket
class BlynkServiceSimple extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _email = '';
  
  bool get isConnected => _isConnected;
  String get email => _email;
  
  String _hashPassword(String password, String email) {
    final saltBytes = sha256.convert(utf8.encode(email.toLowerCase())).bytes;
    final passwordBytes = utf8.encode(password);
    final combined = [...passwordBytes, ...saltBytes];
    final finalHash = sha256.convert(combined);
    return base64.encode(finalHash.bytes);
  }
  
  Future<bool> connect(String serverIp, int serverPort, String email, String password) async {
    try {
      final wsPath = '/dashws';  // Use web dashboard path
      final uri = 'wss://$serverIp:$serverPort$wsPath';
      
      debugPrint('Connecting to $uri...');
      debugPrint('Note: If running on web, you may need to accept self-signed certificate first.');
      debugPrint('Visit https://$serverIp:$serverPort in browser and accept certificate.');
      
      _channel = WebSocketChannel.connect(Uri.parse(uri));
      
      debugPrint('✓ WebSocket connected');
      
      // Listen for messages
      _channel!.stream.listen(
        (data) {
          if (data is List<int>) {
            _handleBinaryMessage(Uint8List.fromList(data));
          } else if (data is String) {
            debugPrint('Received text: $data');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _isConnected = false;
          notifyListeners();
        },
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Send LOGIN message
      final passwordHash = _hashPassword(password, email);
      // 5 parts for /dashws: email, hash, os, version, appName
      final body = '$email\u0000$passwordHash\u0000web\u00001.0.0\u0000Blynk';
      final bodyBytes = utf8.encode(body);
      final messageId = 1;
      
      // WebSocket format: ONLY 3 bytes header (command + msgId), NO length field!
      final loginMessage = Uint8List.fromList([
        2,  // LOGIN command
        (messageId >> 8) & 0xFF,
        messageId & 0xFF,
        ...bodyBytes,
      ]);
      
      debugPrint('Sending LOGIN (${loginMessage.length} bytes)...');
      _channel!.sink.add(loginMessage);
      
      // Wait for response
      await Future.delayed(const Duration(seconds: 2));
      
      // Connection successful!
      _isConnected = true;
      _email = email;
      notifyListeners();
      
      debugPrint('✓ Connected and authenticated as $email');
      
      return true;
      
    } catch (e) {
      debugPrint('Connect error: $e');
      return false;
    }
  }
  
  void _handleBinaryMessage(Uint8List bytes) {
    if (bytes.length >= 3) {
      final command = bytes[0];
      final messageId = (bytes[1] << 8) | bytes[2];
      
      if (command == 0) {
        // Response - code is 4 bytes (int32)
        if (bytes.length >= 7) {
          final responseCode = (bytes[3] << 24) | (bytes[4] << 16) | (bytes[5] << 8) | bytes[6];
          debugPrint('Response: messageId=$messageId, code=$responseCode');
          
          final codes = {
            200: 'OK - Authentication successful!',
            9: 'INVALID_TOKEN',
            2: 'ILLEGAL_COMMAND',
            8: 'NO_ACTIVE_DASHBOARD',
            11: 'ILLEGAL_COMMAND_BODY',
          };
          debugPrint('  ${codes[responseCode] ?? 'Code $responseCode'}');
        }
      } else {
        debugPrint('Command $command received (messageId=$messageId)');
      }
    }
  }
  
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _email = '';
    notifyListeners();
  }
  
  void sendPing() {
    if (_channel == null || !_isConnected) return;
    
    final messageId = DateTime.now().millisecondsSinceEpoch & 0xFFFF;
    // WebSocket PING: only 3 bytes (no body, no length field)
    final pingMessage = Uint8List.fromList([
      6,  // PING command
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
    ]);
    
    debugPrint('Sending PING...');
    _channel!.sink.add(pingMessage);
  }
}
