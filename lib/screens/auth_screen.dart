import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _serverIpController = TextEditingController(text: '192.168.1.9');
  final _serverPortController = TextEditingController(text: '9443');
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showServerConfig = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _serverIpController.dispose();
    _serverPortController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServerConfig();
    });
  }

  Future<void> _loadServerConfig() async {
    try {
      final authService = context.read<AuthService>();
      final config = await authService.getServerConfig();
      if (mounted) {
        setState(() {
          _serverIpController.text = config['ip'] ?? 'localhost';
          _serverPortController.text = config['port']?.toString() ?? '8080';
        });
      }
      debugPrint('Server config loaded: $config');
    } catch (e) {
      debugPrint('Error loading server config: $e');
    }
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!_isLogin && _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    debugPrint('=== Auth Submit ===');
    debugPrint('Mode: ${_isLogin ? "Login" : "Register"}');
    debugPrint('Email: ${_emailController.text.trim()}');
    debugPrint('Server IP: ${_serverIpController.text.trim()}');
    debugPrint('Server Port: ${_serverPortController.text}');

    final authService = context.read<AuthService>();
    
    // Save server config
    await authService.saveServerConfig(
      _serverIpController.text.trim(),
      int.tryParse(_serverPortController.text) ?? 8080,
    );
    
    debugPrint('Calling authService.${_isLogin ? "login" : "register"}...');
    
    bool success;

    if (_isLogin) {
      success = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    }

    debugPrint('Auth result: $success');
    debugPrint('=== End Auth ===');

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Show error with certificate instruction
      final serverIp = _serverIpController.text.trim();
      final serverPort = _serverPortController.text.trim();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isLogin 
                  ? 'Could not connect to Blynk server' 
                  : 'Registration failed'),
              const SizedBox(height: 16),
              const Text(
                'For web browsers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Open a new tab'),
              Text('2. Visit https://$serverIp:$serverPort'),
              const Text('3. Click "Advanced" → "Proceed to ... (unsafe)"'),
              const Text('4. Return here and try again'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.cloud_circle,
                        size: 80,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CYDS Blynk',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (!_isLogin) ...[
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: Row(
                          children: [
                            Icon(Icons.settings, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Server Settings',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        initiallyExpanded: _showServerConfig,
                        onExpansionChanged: (expanded) {
                          setState(() => _showServerConfig = expanded);
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _serverIpController,
                                  decoration: InputDecoration(
                                    labelText: 'Server IP',
                                    hintText: '192.168.1.9 or localhost',
                                    prefixIcon: const Icon(Icons.computer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _serverPortController,
                                  decoration: InputDecoration(
                                    labelText: 'Server Port',
                                    hintText: '9443 or 8080',
                                    prefixIcon: const Icon(Icons.numbers),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _isLogin ? 'LOGIN' : 'SIGN UP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() => _isLogin = !_isLogin);
                        },
                        child: Text(
                          _isLogin
                              ? 'Don\'t have an account? Sign Up'
                              : 'Already have an account? Login',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
