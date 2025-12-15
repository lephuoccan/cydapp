import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/blynk_service_simple.dart';
import 'dashboard_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Connect to Blynk server for real-time data
      _connectToBlynkServer();
    });
  }
  
  Future<void> _connectToBlynkServer() async {
    final authService = context.read<AuthService>();
    final blynkService = context.read<BlynkServiceSimple>();
    
    debugPrint('=== _connectToBlynkServer ===');
    debugPrint('BlynkService.isConnected: ${blynkService.isConnected}');
    
    if (!blynkService.isConnected) {
      final config = await authService.getServerConfig();
      
      // Try to get password from AuthService (memory) first, then SharedPreferences
      String? savedPassword = authService.lastPassword;
      debugPrint('Password from AuthService (memory): ${savedPassword.isEmpty ? "EMPTY" : "EXISTS (${savedPassword.length} chars)"}');
      
      if (savedPassword.isEmpty) {
        // Fallback to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        savedPassword = prefs.getString('blynk_password');
        debugPrint('Password from SharedPreferences: ${savedPassword == null ? "NULL" : "EXISTS (${savedPassword.length} chars)"}');
      }
      
      if (savedPassword == null || savedPassword.isEmpty) {
        // No password available, ask user
        debugPrint('❌ No saved password, asking user...');
        if (!mounted) return;
        await _askPasswordAndConnect(config);
      } else {
        // Auto-connect with saved password
        debugPrint('✌️ Auto-connecting with saved password from ${authService.lastPassword.isNotEmpty ? "AuthService (memory)" : "SharedPreferences"}...');
        
        final success = await blynkService.connect(
          config['ip'] ?? 'cyds.servehttp.com',
          config['port'] ?? 9443,
          authService.currentUser?.email ?? '',
          savedPassword,
        );
        
        if (!mounted) return;
        
        if (success) {
          debugPrint('✓ Auto-connect successful!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Connected! Receiving live data from ${authService.currentUser?.email}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Auto-connect failed - show specific error
          debugPrint('✗ Auto-connect failed: ${blynkService.lastError}');
          
          // Check if it's a password error (code 9 = Invalid token)
          final isPasswordError = blynkService.lastError.contains('Invalid token');
          
          if (isPasswordError) {
            // Password wrong - ask for new password
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_getErrorMessage(blynkService.lastError))),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
            await _askPasswordAndConnect(config);
          } else {
            // Other error - show notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_getErrorMessage(blynkService.lastError))),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'RETRY',
                  textColor: Colors.white,
                  onPressed: () => _askPasswordAndConnect(config),
                ),
              ),
            );
          }
        }
      }
    } else {
      debugPrint('Already connected to BlynkService');
    }
    debugPrint('=== End _connectToBlynkServer ===');
  }
  
  Future<void> _askPasswordAndConnect(Map<String, dynamic> config) async {
    final authService = context.read<AuthService>();
    final blynkService = context.read<BlynkServiceSimple>();
    
    if (!mounted) return;
    
    final passwordController = TextEditingController();
    
    // Show password dialog with retry logic
    bool shouldRetry = true;
    
    while (shouldRetry) {
      shouldRetry = false;
      String? errorMessage;
      
      final password = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  errorMessage != null ? Icons.error_outline : Icons.wifi,
                  color: errorMessage != null ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(errorMessage != null ? 'Connection Failed' : 'Real-time Connection'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const Text('Enter password to receive live ESP32 data:'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  onSubmitted: (_) => Navigator.pop(context, passwordController.text),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    helperText: errorMessage != null ? 'Please check your password' : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, passwordController.text),
                child: const Text('Connect'),
              ),
            ],
          ),
        ),
      );
      
      if (password != null && password.isNotEmpty) {
        if (!mounted) return;
        
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connecting to server...'),
                  ],
                ),
              ),
            ),
          ),
        );
        
        final success = await blynkService.connect(
          config['ip'] ?? 'cyds.servehttp.com',
          config['port'] ?? 9443,
          authService.currentUser?.email ?? '',
          password,
        );
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        
        if (!success) {
          // Analyze error and show appropriate message
          errorMessage = _getErrorMessage(blynkService.lastError);
          
          // Retry with error message
          shouldRetry = true;
        } else {
          // Success - save password for next time
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('blynk_password', password);
          debugPrint('✅ Password saved for auto-login');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Connected to ${authService.currentUser?.email ?? "server"}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
  
  /// Get user-friendly error message based on error code/message
  String _getErrorMessage(String rawError) {
    if (rawError.isEmpty) {
      return '⚠️ Kết nối thất bại. Kiểm tra lại mạng.';
    }
    
    // Code 9: Invalid token = SAI PASSWORD
    if (rawError.contains('Invalid token') ||
        rawError.contains('Wrong email or password')) {
      return '❌ Sai mật khẩu. Vui lòng thử lại.';
    }
    
    // Code 3: User not registered = SAI EMAIL (user không tồn tại)
    if (rawError.contains('User not registered') ||
        rawError.contains('not registered')) {
      return '❌ Email không tồn tại. Vui lòng đăng ký trước.';
    }
    
    // Code 5: User not authenticated = Có thể do quota hoặc lỗi server
    if (rawError.contains('User not authenticated') ||
        rawError.contains('not authenticated')) {
      return '⚠️ Xác thực thất bại. Kiểm tra lại thông tin hoặc thử lại sau.';
    }
    
    // Code 1: Quota limit
    if (rawError.contains('Quota limit')) {
      return '⚠️ Vượt quá giới hạn server. Thử lại sau.';
    }
    
    // Code 16: Timeout
    if (rawError.contains('timeout') || rawError.contains('Timeout')) {
      return '⏱️ Hết thời gian chờ. Kiểm tra server và mạng.';
    }
    
    // Connection errors
    if (rawError.contains('Connection error')) {
      return '🌐 Lỗi mạng. Kiểm tra WiFi/VPN.';
    }
    
    // Code 8: No active dashboard
    if (rawError.contains('No active dashboard')) {
      return '📊 Không có dashboard. Tạo dashboard trước.';
    }
    
    // Code 2: Illegal command
    if (rawError.contains('Illegal command')) {
      return '⚠️ Lỗi giao thức. Liên hệ hỗ trợ.';
    }
    
    // Default: show raw error
    return '❌ $rawError';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthService>(
          builder: (context, authService, child) {
            return Text('Hello, ${authService.currentUser?.name ?? "User"}');
          },
        ),
        actions: [
          // Dashboard button
          Consumer<BlynkServiceSimple>(
            builder: (context, blynkService, child) {
              if (blynkService.isConnected) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reload profile button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reload Profile',
                      onPressed: () async {
                        await blynkService.loadProfile();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(blynkService.profileJson != null 
                                  ? 'Profile loaded (${blynkService.profileJson!.length} chars)'
                                  : 'Waiting for profile...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    // Dashboard button
                    IconButton(
                      icon: const Icon(Icons.dashboard_outlined),
                      tooltip: 'Dashboards',
                      onPressed: () {
                        // Open new dashboard view screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardViewScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear saved password
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('blynk_password');
              debugPrint('🔓 Password cleared from SharedPreferences');
              
              final authService = context.read<AuthService>();
              await authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Real-time ESP32 Data Card
          Consumer<BlynkServiceSimple>(
            builder: (context, blynkService, child) {
              if (blynkService.isConnected && blynkService.pinValues.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sensors_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'ESP32 Real-time Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: blynkService.pinValues.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
      floatingActionButton: Consumer<BlynkServiceSimple>(
        builder: (context, blynkService, child) {
          if (blynkService.isConnected) {
            return FloatingActionButton.extended(
              onPressed: () => _showTestPinDialog(blynkService),
              icon: const Icon(Icons.send),
              label: const Text('Send to ESP32'),
              backgroundColor: Colors.deepPurple,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _showTestPinDialog(BlynkServiceSimple blynkService) async {
    final pinController = TextEditingController(text: '1');
    final valueController = TextEditingController(text: '888');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.send, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Send Virtual Pin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send a value to ESP32 via Virtual Pin:', 
              style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pin (0-255)',
                      border: OutlineInputBorder(),
                      prefixText: 'V',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example ESP32 code:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BLYNK_WRITE(V${pinController.text}) {\n  int val = param.asInt();\n  Serial.println(val);\n}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final pin = int.tryParse(pinController.text);
              final value = valueController.text;
              
              if (pin != null) {
                blynkService.sendVirtualPin(pin, value);
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('✅ Sent V$pin = "$value" to ESP32'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
