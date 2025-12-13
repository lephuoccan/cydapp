import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/blynk_message.dart';

class BlynkConnection extends ChangeNotifier {
  Socket? _socket;
  final String serverUrl;
  final int serverPort;
  bool _isConnected = false;
  int _messageId = 1;
  final Map<int, Completer<BlynkMessage>> _pendingRequests = {};
  final Map<String, dynamic> _pinValues = {};
  StreamSubscription? _subscription;
  final List<int> _buffer = [];

  BlynkConnection({
    required this.serverUrl,
    this.serverPort = 8080,
  });

  bool get isConnected => _isConnected;
  Map<String, dynamic> get pinValues => Map.unmodifiable(_pinValues);

  Future<bool> connect(String authToken, {String? serverIp, int? serverPort}) async {
    try {
      final host = serverIp ?? serverUrl;
      final port = serverPort ?? this.serverPort;
      debugPrint('Connecting to Blynk server: $host:$port');
      
      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );

      debugPrint('Socket connected!');

      _subscription = _socket!.listen(
        _onData,
        onDone: _onDisconnect,
        onError: _onError,
        cancelOnError: false,
      );

      // Wait a bit before sending login
      await Future.delayed(const Duration(milliseconds: 100));

      // Send login message
      final loginMessage = BlynkMessage(
        commandId: BlynkCommand.login,
        messageId: _getNextMessageId(),
        parameters: [authToken],
      );
      
      debugPrint('Sending login with token: $authToken');
      await _sendMessage(loginMessage);

      // Wait for response
      await Future.delayed(const Duration(milliseconds: 500));

      _isConnected = true;
      notifyListeners();
      
      // Start ping timer
      _startPingTimer();
      
      debugPrint('Connection established!');
      return true;
    } catch (e) {
      debugPrint('Connection error: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  void disconnect() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _pendingRequests.clear();
    _pinValues.clear();
    _buffer.clear();
    notifyListeners();
  }

  Future<void> _sendMessage(BlynkMessage message) async {
    if (_socket == null) return;
    
    final data = message.encode();
    _socket!.add(data);
    
    debugPrint('Sent: $message (${data.length} bytes)');
  }

  void _onData(Uint8List data) {
    debugPrint('Received ${data.length} bytes');
    _buffer.addAll(data);
    _processBuffer();
  }

  void _processBuffer() {
    while (_buffer.length >= 5) {
      final command = _buffer[0];
      
      int totalLength;
      
      if (command == 0) {
        // Response message - no body, just 5 bytes total
        totalLength = 5;
      } else {
        // Regular message - check body length
        final length = (_buffer[3] << 8) | _buffer[4];
        totalLength = 5 + length;
      }

      if (_buffer.length < totalLength) {
        // Wait for more data
        return;
      }

      // Extract message
      final messageData = _buffer.sublist(0, totalLength);
      _buffer.removeRange(0, totalLength);

      try {
        final message = BlynkMessage.parse(messageData);
        _handleMessage(message);
      } catch (e) {
        debugPrint('Message parse error: $e');
      }
    }
  }

  void _handleMessage(BlynkMessage message) {
    debugPrint('Received: $message');

    // Handle response for pending requests
    if (_pendingRequests.containsKey(message.messageId)) {
      _pendingRequests[message.messageId]!.complete(message);
      _pendingRequests.remove(message.messageId);
      return;
    }

    // Handle specific commands
    if (message.commandId == BlynkCommand.response) {
      final responseCode = message.parameters.isNotEmpty 
          ? int.tryParse(message.parameters[0]) ?? 0
          : 0;
      
      final codeNames = {
        200: 'OK',
        2: 'ILLEGAL_COMMAND',
        3: 'NO_ACTIVE_DASHBOARD',
        4: 'INVALID_TOKEN',
        5: 'ILLEGAL_COMMAND_BODY',
        6: 'NOT_REGISTERED',
        7: 'ALREADY_REGISTERED',
        8: 'NOT_AUTHENTICATED',
        9: 'NOT_ALLOWED',
        11: 'DEVICE_NOT_IN_NETWORK',
        12: 'NO_DATA',
        13: 'DEVICE_WENT_OFFLINE',
        14: 'ALREADY_LOGGED_IN',
        17: 'DEVICE_IS_OFFLINE',
        18: 'SERVER_EXCEPTION',
      };
      
      final codeName = codeNames[responseCode] ?? 'UNKNOWN';
      debugPrint('Response code: $responseCode ($codeName)');
      
      if (responseCode == 200) {
        debugPrint('Login successful!');
        _isConnected = true;
        notifyListeners();
      } else {
        debugPrint('Server error: $responseCode - $codeName');
        _isConnected = false;
        notifyListeners();
        disconnect();
      }
    } else if (message.commandId == BlynkCommand.hardware) {
      _handleHardwareCommand(message);
    }
  }



  void _handleHardwareCommand(BlynkMessage message) {
    if (message.parameters.isEmpty) return;

    final command = message.parameters[0];
    
    if (command == HardwareCommand.virtualWrite && message.parameters.length >= 3) {
      final pin = 'V${message.parameters[1]}';
      final value = message.parameters[2];
      _pinValues[pin] = value;
      notifyListeners();
    } else if (command == HardwareCommand.digitalWrite && message.parameters.length >= 3) {
      final pin = 'D${message.parameters[1]}';
      final value = message.parameters[2];
      _pinValues[pin] = value;
      notifyListeners();
    } else if (command == HardwareCommand.analogWrite && message.parameters.length >= 3) {
      final pin = 'A${message.parameters[1]}';
      final value = message.parameters[2];
      _pinValues[pin] = value;
      notifyListeners();
    }
  }

  void _onDisconnect() {
    debugPrint('Disconnected from Blynk server');
    _isConnected = false;
    notifyListeners();
  }

  void _onError(Object error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    notifyListeners();
  }

  int _getNextMessageId() {
    _messageId++;
    if (_messageId > 0xFFFF) _messageId = 1;
    return _messageId;
  }

  Timer? _pingTimer;
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isConnected) {
        _sendMessage(BlynkMessage(
          commandId: BlynkCommand.ping,
          messageId: _getNextMessageId(),
          parameters: [],
        ));
      }
    });
  }

  // Widget operations
  Future<void> virtualWrite(int pin, String value) async {
    await _sendMessage(BlynkMessage(
      commandId: BlynkCommand.hardware,
      messageId: _getNextMessageId(),
      parameters: [HardwareCommand.virtualWrite, pin.toString(), value],
    ));
  }

  Future<void> digitalWrite(int pin, int value) async {
    await _sendMessage(BlynkMessage(
      commandId: BlynkCommand.hardware,
      messageId: _getNextMessageId(),
      parameters: [HardwareCommand.digitalWrite, pin.toString(), value.toString()],
    ));
  }

  Future<void> analogWrite(int pin, int value) async {
    await _sendMessage(BlynkMessage(
      commandId: BlynkCommand.hardware,
      messageId: _getNextMessageId(),
      parameters: [HardwareCommand.analogWrite, pin.toString(), value.toString()],
    ));
  }

  Future<void> syncWidget(int pin) async {
    await _sendMessage(BlynkMessage(
      commandId: BlynkCommand.hardwareSync,
      messageId: _getNextMessageId(),
      parameters: ['vr', pin.toString()],
    ));
  }

  String? getPinValue(String pin) {
    return _pinValues[pin]?.toString();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
