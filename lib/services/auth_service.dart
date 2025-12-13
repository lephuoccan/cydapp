import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  String _lastPassword = ''; // Store in memory only for auto-reconnect
  String _lastError = ''; // Store last error message
  int _lastErrorCode = 0; // Store last error code

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoggedIn => _isAuthenticated;
  String get lastPassword => _lastPassword; // For BlynkServiceSimple auto-connect
  String get lastError => _lastError;
  int get lastErrorCode => _lastErrorCode;

  // Simulated database - in production này sẽ call API
  final Map<String, Map<String, dynamic>> _users = {};

  // Hash password like Blynk server: MD.update(password), MD.digest(SHA256(email.toLowerCase()))
  String _hashPassword(String password, String email) {
    final saltBytes = sha256.convert(utf8.encode(email.toLowerCase())).bytes;
    final passwordBytes = utf8.encode(password);
    final combined = [...passwordBytes, ...saltBytes];
    final finalHash = sha256.convert(combined);
    
    return base64.encode(finalHash.bytes);
  }

  // Server configuration
  Future<void> saveServerConfig(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    await prefs.setInt('server_port', port);
  }

  Future<Map<String, dynamic>> getServerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ip': prefs.getString('server_ip') ?? '192.168.1.9',
      'port': prefs.getInt('server_port') ?? 9443,
    };
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load users from storage
    final usersJson = prefs.getString('users');
    if (usersJson != null) {
      final Map<String, dynamic> usersMap = json.decode(usersJson);
      _users.clear();
      usersMap.forEach((key, value) {
        _users[key] = Map<String, dynamic>.from(value);
      });
    }
    
    // Load current user session
    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      _currentUser = User.fromJson(json.decode(userJson));
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      // Check if user exists
      if (_users.containsKey(email)) {
        return false;
      }

      // Create user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      _users[email] = {
        'id': userId,
        'email': email,
        'password': password, // In production: hash this!
        'name': name,
      };

      // Save users to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('users', json.encode(_users));

      // Auto login
      return await login(email, password);
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      debugPrint('=== AuthService.login ===');
      debugPrint('Email: $email');
      
      // Store password in memory IMMEDIATELY (before async operations)
      _lastPassword = password;
      debugPrint('✓ Password stored in memory (${password.length} chars)');
      
      // Get server config
      final serverConfig = await getServerConfig();
      final serverIp = serverConfig['ip'] as String;
      final serverPort = serverConfig['port'] as int;
      
      debugPrint('Connecting to Blynk server: $serverIp:$serverPort');
      
      // Always use WebSocket for web compatibility
      final success = await _loginViaWebSocket(serverIp, serverPort, email, password);
      
      if (!success) {
        // Clear password if login failed
        _lastPassword = '';
        debugPrint('✗ Login failed, password cleared from memory');
      }
      
      return success;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> _loginViaWebSocket(String serverIp, int serverPort, String email, String password) async {
    WebSocketChannel? channel;
    try {
      final wsPath = '/dashws';  // Use web dashboard path
      final uri = 'wss://$serverIp:$serverPort$wsPath';
      debugPrint('Connecting via WebSocket: $uri');
      debugPrint('Note: On web, you may need to accept certificate at https://$serverIp:$serverPort first');
      
      channel = WebSocketChannel.connect(Uri.parse(uri));
      
      debugPrint('✓ WebSocket connected');
      
      final completer = Completer<bool>();
      
      // Listen for response
      channel.stream.listen(
        (data) {
          if (data is List<int> && !completer.isCompleted) {
            final bytes = Uint8List.fromList(data);
            debugPrint('← Received ${bytes.length} bytes');
            
            if (bytes.length >= 7) {
              final command = bytes[0];
              final messageId = (bytes[1] << 8) | bytes[2];
              
              if (command == 0) {
                final responseCode = (bytes[3] << 24) | (bytes[4] << 16) | (bytes[5] << 8) | bytes[6];
                debugPrint('Response: messageId=$messageId, code=$responseCode');
                
                if (responseCode == 200) {
                  debugPrint('✓ Login successful!');
                  _lastError = '';
                  _lastErrorCode = 0;
                  completer.complete(true);
                } else {
                  final codeNames = {
                    1: 'Quota limit exceeded',
                    2: 'Illegal command',
                    3: 'User not registered',
                    4: 'User already registered',
                    5: 'User not authenticated',
                    6: 'Operation not allowed',
                    7: 'Device not in network',
                    8: 'No active dashboard',
                    9: 'Invalid token',
                  };
                  _lastErrorCode = responseCode;
                  _lastError = codeNames[responseCode] ?? 'Unknown error ($responseCode)';
                  debugPrint('✗ Login failed: $_lastError');
                  completer.complete(false);
                }
              }
            }
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _lastError = 'Connection error';
          _lastErrorCode = -1;
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          debugPrint('WebSocket closed');
          if (_lastError.isEmpty) {
            _lastError = 'Connection closed';
            _lastErrorCode = -2;
          }
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      
      // Wait for connection to be ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Send LOGIN message
      final passwordHash = _hashPassword(password, email);
      debugPrint('Password hash: $passwordHash');
      
      final appName = 'Blynk';
      final versionOs = 'web';
      final versionNumber = '1.0.0';
      final body = '$email\u0000$passwordHash\u0000$versionOs\u0000$versionNumber\u0000$appName';
      final bodyBytes = utf8.encode(body);
      final messageId = 1;
      
      // WebSocket format: ONLY 3 bytes header, NO length field!
      final loginMessage = Uint8List.fromList([
        2,  // LOGIN command
        (messageId >> 8) & 0xFF,
        messageId & 0xFF,
        ...bodyBytes,
      ]);
      
      debugPrint('→ Sending LOGIN (${loginMessage.length} bytes)');
      channel.sink.add(loginMessage);
      
      // Wait for response with timeout
      final success = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('✗ Login timeout');
          return false;
        },
      );
      
      if (success) {
        // Save session locally
        final userId = DateTime.now().millisecondsSinceEpoch.toString();
        
        _currentUser = User(
          id: userId,
          email: email,
          name: email.split('@')[0],
          token: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        
        _isAuthenticated = true;
        
        // Save to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentUser', json.encode(_currentUser!.toJson()));
        
        debugPrint('✓ Login complete!');
        debugPrint('=== End AuthService.login ===');
        
        notifyListeners();
        return true;
      }
      
      return false;
      
    } catch (e) {
      debugPrint('WebSocket login error: $e');
      return false;
    } finally {
      debugPrint('Closing WebSocket...');
      await channel?.sink.close();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _lastPassword = ''; // Clear password from memory

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');

    notifyListeners();
  }
}
