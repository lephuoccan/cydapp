import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:archive/archive.dart';
import 'blynk_constants.dart';

/// Simple Blynk service that connects via WebSocket
class BlynkServiceSimple extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _email = '';
  String _password = '';
  String _serverIp = '';
  int _serverPort = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final Map<String, String> _pinValues = {}; // Store pin values from hardware
  int _lastResponseCode = 0;
  String _lastError = '';
  final _loginCompleter = <int, Completer<int>>{}; // Track login responses
  String? _profileJson; // Store user profile JSON from server
  String? _lastProfileHash; // Track profile hash to detect changes
  int _nextMessageId = 2; // Start from 2 (1 is used for login)
  int _activeDashboardId = 0; // Active dashboard ID for sending commands
  int _activeDeviceId = 0; // Active device ID
  
  bool get isConnected => _isConnected;
  String get email => _email;
  Map<String, String> get pinValues => Map.unmodifiable(_pinValues);
  String get lastError => _lastError;
  String? get profileJson => _profileJson;
  
  /// Get pin value by pin number and type
  /// Example: getPinValue(0, 'VIRTUAL') returns value of V0
  String? getPinValue(int pin, {String pinType = 'VIRTUAL'}) {
    String prefix;
    switch (pinType.toUpperCase()) {
      case 'VIRTUAL':
        prefix = 'V';
        break;
      case 'DIGITAL':
        prefix = 'D';
        break;
      case 'ANALOG':
        prefix = 'A';
        break;
      default:
        prefix = 'V';
    }
    return _pinValues['$prefix$pin'];
  }
  
  /// Set active dashboard and device for sending commands
  void setActiveDashboard(int dashboardId, {int deviceId = 0}) {
    _activeDashboardId = dashboardId;
    _activeDeviceId = deviceId;
    debugPrint('✓ Active dashboard set to: $dashboardId-$deviceId');
  }
  
  String _hashPassword(String password, String email) {
    final saltBytes = sha256.convert(utf8.encode(email.toLowerCase())).bytes;
    final passwordBytes = utf8.encode(password);
    final combined = [...passwordBytes, ...saltBytes];
    final finalHash = sha256.convert(combined);
    return base64.encode(finalHash.bytes);
  }
  
  Future<bool> connect(String serverIp, int serverPort, String email, String password) async {
    // Store credentials for reconnection
    _serverIp = serverIp;
    _serverPort = serverPort;
    _email = email;
    _password = password;
    
    return _doConnect();
  }
  
  Future<bool> _doConnect() async {
    try {
      final wsPath = '/dashws';  // Use web dashboard path
      final uri = 'wss://$_serverIp:$_serverPort$wsPath';
      
      debugPrint('Connecting to $uri...');
      debugPrint('Note: If running on web, you may need to accept self-signed certificate first.');
      debugPrint('Visit https://$_serverIp:$_serverPort in browser and accept certificate.');
      
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
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _isConnected = false;
          notifyListeners();
          _scheduleReconnect();
        },
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Send LOGIN message
      final passwordHash = _hashPassword(_password, _email);
      // 5 parts for /dashws: email, hash, os, version, appName
      final body = '$_email\u0000$passwordHash\u0000web\u00001.0.0\u0000Blynk';
      final bodyBytes = utf8.encode(body);
      final messageId = 1;
      
      // WebSocket format: ONLY 3 bytes header (command + msgId), NO length field!
      final loginMessage = Uint8List.fromList([
        BlynkCommand.login,  // LOGIN command
        (messageId >> 8) & 0xFF,
        messageId & 0xFF,
        ...bodyBytes,
      ]);
      
      debugPrint('Sending LOGIN (${loginMessage.length} bytes)...');
      
      // Create completer to wait for login response
      final completer = Completer<int>();
      _loginCompleter[messageId] = completer;
      
      _channel!.sink.add(loginMessage);
      
      // Wait for response with timeout
      try {
        _lastResponseCode = await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _lastError = 'Login timeout - server not responding';
            return -1;
          },
        );
      } finally {
        _loginCompleter.remove(messageId);
      }
      
      // Check response code
      if (_lastResponseCode == BlynkStatus.ok) {
        // Connection successful!
        _isConnected = true;
        _lastError = '';
        _reconnectTimer?.cancel(); // Cancel reconnect timer on successful connection
        
        // Start periodic ping to keep connection alive (every 10 seconds)
        _startPingTimer();
        
        debugPrint('✓ Connected and authenticated as $_email');
        
        // Automatically load profile after login
        await loadProfile();
        
        notifyListeners();
        return true;
      } else if (_lastResponseCode == -1) {
        // Timeout already set error message
        debugPrint('❌ $_lastError');
        return false;
      } else {
        // Use BlynkStatus.getMessage() for all error codes
        _lastError = BlynkStatus.getMessage(_lastResponseCode);
        debugPrint('❌ $_lastError');
        return false;
      }
      
    } catch (e) {
      _lastError = 'Connection error: $e';
      debugPrint('❌ $_lastError');
      return false;
    }
  }
  
  void _handleBinaryMessage(Uint8List bytes) {
    if (bytes.length >= 3) {
      final command = bytes[0];
      final messageId = (bytes[1] << 8) | bytes[2];
      
      if (command == BlynkCommand.response) {
        // Response - code is 4 bytes (int32)
        if (bytes.length >= 7) {
          final responseCode = (bytes[3] << 24) | (bytes[4] << 16) | (bytes[5] << 8) | bytes[6];
          debugPrint('Response: messageId=$messageId, code=$responseCode');
          debugPrint('  ${BlynkStatus.getMessage(responseCode)}');
          
          // Complete login completer if waiting
          if (_loginCompleter.containsKey(messageId)) {
            _loginCompleter[messageId]!.complete(responseCode);
          }
        }
      } else if (command == BlynkCommand.loadProfileGzipped) {
        // LOAD_PROFILE_GZIPPED (24) - User profile data from server
        if (bytes.length > 3) {
          // Profile is DEFLATE (ZLib) compressed JSON - not GZip!
          try {
            // Skip header (3 bytes), rest is deflated data
            final compressedData = bytes.sublist(3);
            
            // Decompress using ZLibDecoder (server uses DeflaterOutputStream)
            final decompressed = ZLibDecoder().decodeBytes(compressedData);
            final profileJson = utf8.decode(decompressed);
            
            // Check if profile actually changed
            final newHash = profileJson.hashCode.toString();
            final hasChanged = newHash != _lastProfileHash;
            
            if (hasChanged) {
              debugPrint('✅ Profile changed (${profileJson.length} chars)');
              _lastProfileHash = newHash;
              _profileJson = profileJson;
              notifyListeners();
            } else {
              debugPrint('ℹ️  Profile unchanged, skipping update');
            }
          } catch (e) {
            debugPrint('❌ Error parsing profile: $e');
          }
        }
      } else if (command == BlynkCommand.hardware) {
        // HARDWARE command - data from ESP32
        if (bytes.length > 3) {
          final body = String.fromCharCodes(bytes.sublist(3));
          final parts = body.split(BlynkProtocol.bodySeparator);
          
          if (parts.length >= 4) {
            final cmd = parts[1];
            final pin = parts[2];
            final value = parts[3];
            
            if (cmd == BlynkPinCommand.virtualWrite || cmd == BlynkPinCommand.virtualRead || cmd == 'vm') {
              _pinValues['V$pin'] = value;
              notifyListeners();
            } else if (cmd == BlynkPinCommand.digitalWrite || cmd == BlynkPinCommand.digitalRead) {
              _pinValues['D$pin'] = value;
              notifyListeners();
            } else if (cmd == BlynkPinCommand.analogWrite || cmd == BlynkPinCommand.analogRead) {
              _pinValues['A$pin'] = value;
              notifyListeners();
            }
          } else {
            debugPrint('⚠️  Invalid HARDWARE format: expected 4+ parts, got ${parts.length}');
            debugPrint('   Body: "$body"');
            debugPrint('   Parts: $parts');
          }
        }
      } else if (command == BlynkCommand.activateDashboard) {
        // ACTIVATE_DASHBOARD response (7) - Server confirms dashboard is active
        // Reload profile to sync latest widget configurations
        debugPrint('🟢 ActivateDashboard confirmed by server - reloading profile...');
        loadProfile(); // Don't await here since _handleBinaryMessage is not async
      } else if (command == BlynkCommand.appSync) {
        // APP_SYNC (25) - Sync pin values from server
        if (bytes.length > 3) {
          final body = String.fromCharCodes(bytes.sublist(3));
          final parts = body.split(BlynkProtocol.bodySeparator);
          
          if (parts.length >= 4) {
            final cmd = parts[1];
            final pin = parts[2];
            final value = parts[3];
            
            if (cmd == BlynkPinCommand.virtualWrite || cmd == BlynkPinCommand.virtualRead || cmd == 'vm') {
              _pinValues['V$pin'] = value;
              notifyListeners();
            } else if (cmd == BlynkPinCommand.digitalWrite || cmd == BlynkPinCommand.digitalRead) {
              _pinValues['D$pin'] = value;
              notifyListeners();
            } else if (cmd == BlynkPinCommand.analogWrite || cmd == BlynkPinCommand.analogRead) {
              _pinValues['A$pin'] = value;
              notifyListeners();
            }
          }
        }
      } else {
        debugPrint('${BlynkCommand.getName(command)} received (messageId=$messageId)');
      }
    }
  }
  
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }
  
  void _scheduleReconnect() {
    if (_serverIp.isEmpty) return; // No credentials to reconnect
    
    _reconnectTimer?.cancel();
    debugPrint('⏱️ Will reconnect in 5 seconds...');
    
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      debugPrint('🔄 Attempting to reconnect...');
      final success = await _doConnect();
      if (!success) {
        debugPrint('❌ Reconnect failed, will try again...');
      } else {
        debugPrint('✅ Reconnected successfully!');
      }
    });
  }
  
  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    disconnect();
    super.dispose();
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    
    // Send ping to keep connection alive
    // Server timeout = pingInterval * 2.3 (~23 seconds)
    _pingTimer = Timer.periodic(const Duration(milliseconds: BlynkProtocol.pingInterval), (timer) {
      if (_channel != null && _isConnected) {
        sendPing();
      } else {
        timer.cancel();
      }
    });
    
    debugPrint('⏱️ Ping timer started (interval: ${BlynkProtocol.pingInterval}ms)');
  }
  
  void sendPing() {
    if (_channel == null || !_isConnected) return;
    
    final messageId = DateTime.now().millisecondsSinceEpoch & 0xFFFF;
    // WebSocket PING: only 3 bytes (no body, no length field)
    final pingMessage = Uint8List.fromList([
      BlynkCommand.ping,
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
    ]);
    
    // Silent PING - no log spam
    _channel!.sink.add(pingMessage);
  }
  
  /// Send virtual pin value to ESP32
  /// Example: sendVirtualPin(1, "100") sends V1 = 100
  Future<void> sendVirtualPin(int pin, String value) async {
    if (_channel == null || !_isConnected) {
      debugPrint('❌ Cannot send: not connected');
      return;
    }
    
    if (_activeDashboardId == 0) {
      debugPrint('⚠️  No active dashboard set, using default');
    }
    
    // Format: "dashId-deviceId\0vw\0pin\0value"
    final body = '$_activeDashboardId-$_activeDeviceId${BlynkProtocol.bodySeparator}${BlynkPinCommand.virtualWrite}${BlynkProtocol.bodySeparator}$pin${BlynkProtocol.bodySeparator}$value';
    final bodyBytes = utf8.encode(body);
    
    final messageId = DateTime.now().millisecondsSinceEpoch & 0xFFFF;
    
    // HARDWARE command
    final message = Uint8List.fromList([
      BlynkCommand.hardware,
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
      ...bodyBytes,
    ]);
    
    debugPrint('📤 Sending V$pin = $value to dashboard $_activeDashboardId device $_activeDeviceId');
    _channel!.sink.add(message);
    
    // Update local cache immediately for responsive UI
    _pinValues['V$pin'] = value;
    notifyListeners();
  }
  
  /// Send digital pin value to ESP32 (0 or 1)
  Future<void> sendDigitalPin(int pin, int value) async {
    if (value != 0 && value != 1) {
      debugPrint('❌ Digital pin must be 0 or 1');
      return;
    }
    
    if (_channel == null || !_isConnected) {
      debugPrint('❌ Cannot send: not connected');
      return;
    }
    
    final body = '$_activeDashboardId-$_activeDeviceId${BlynkProtocol.bodySeparator}${BlynkPinCommand.digitalWrite}${BlynkProtocol.bodySeparator}$pin${BlynkProtocol.bodySeparator}$value';
    final bodyBytes = utf8.encode(body);
    
    final messageId = DateTime.now().millisecondsSinceEpoch & 0xFFFF;
    
    final message = Uint8List.fromList([
      BlynkCommand.hardware,
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
      ...bodyBytes,
    ]);
    
    debugPrint('📤 Sending D$pin = $value to dashboard $_activeDashboardId device $_activeDeviceId');
    _channel!.sink.add(message);
    
    // Update local cache immediately for responsive UI
    _pinValues['D$pin'] = value.toString();
    notifyListeners();
  }
  
  /// Send analog pin value to ESP32 (0-255)
  Future<void> sendAnalogPin(int pin, int value) async {
    if (value < 0 || value > 255) {
      debugPrint('❌ Analog pin must be 0-255');
      return;
    }
    
    if (_channel == null || !_isConnected) {
      debugPrint('❌ Cannot send: not connected');
      return;
    }
    
    if (_activeDashboardId == 0) {
      debugPrint('⚠️  No active dashboard set, using default');
    }
    
    final body = '$_activeDashboardId-$_activeDeviceId${BlynkProtocol.bodySeparator}${BlynkPinCommand.analogWrite}${BlynkProtocol.bodySeparator}$pin${BlynkProtocol.bodySeparator}$value';
    final bodyBytes = utf8.encode(body);
    
    final messageId = DateTime.now().millisecondsSinceEpoch & 0xFFFF;
    
    final message = Uint8List.fromList([
      BlynkCommand.hardware,
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
      ...bodyBytes,
    ]);
    
    debugPrint('📤 Sending A$pin = $value to dashboard $_activeDashboardId device $_activeDeviceId');
    _channel!.sink.add(message);
    
    // Update local cache immediately for responsive UI
    _pinValues['A$pin'] = value.toString();
    notifyListeners();
  }
  
  // Load user profile (dashboards, widgets, etc.)
  Future<void> loadProfile() async {
    if (_channel == null || !_isConnected) {
      debugPrint('❌ Cannot load profile - not connected');
      return;
    }
    
    final messageId = _nextMessageId++;
    
    // Send LOAD_PROFILE_GZIPPED command with empty body (load all dashboards)
    final message = Uint8List.fromList([
      BlynkCommand.loadProfileGzipped,
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
      // Empty body = load all dashboards
    ]);
    
    debugPrint('📤 Requesting profile (messageId=$messageId)...');
    _channel!.sink.add(message);
  }
  
  /// Activate dashboard to receive real-time updates
  /// Server will send APP_SYNC messages with current pin values
  Future<void> activateDashboard(int dashboardId) async {
    if (_channel == null || !_isConnected) {
      debugPrint('❌ Cannot activate dashboard - not connected');
      return;
    }
    
    final messageId = _nextMessageId++;
    final body = dashboardId.toString();
    final bodyBytes = utf8.encode(body);
    
    final message = Uint8List.fromList([
      BlynkCommand.activateDashboard,
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
      ...bodyBytes,
    ]);
    
    debugPrint('📤 Activating dashboard $dashboardId (messageId=$messageId)...');
    _channel!.sink.add(message);
  }
  
  /// Deactivate dashboard to stop real-time updates
  Future<void> deactivateDashboard(int dashboardId) async {
    if (_channel == null || !_isConnected) {
      debugPrint('❌ Cannot deactivate dashboard - not connected');
      return;
    }
    
    final messageId = _nextMessageId++;
    final body = dashboardId.toString();
    final bodyBytes = utf8.encode(body);
    
    final message = Uint8List.fromList([
      BlynkCommand.deactivateDashboard,
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
      ...bodyBytes,
    ]);
    
    debugPrint('📤 Deactivating dashboard $dashboardId (messageId=$messageId)...');
    _channel!.sink.add(message);
  }
}
