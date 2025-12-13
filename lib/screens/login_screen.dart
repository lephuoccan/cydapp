import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/project_manager.dart';
import '../services/blynk_connection.dart';
import 'projects_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverController = TextEditingController();
  final _portController = TextEditingController();
  final _authTokenController = TextEditingController();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    final projectManager = context.read<ProjectManager>();
    _serverController.text = projectManager.serverUrl;
    _portController.text = projectManager.serverPort.toString();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _authTokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_authTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter auth token')),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final projectManager = context.read<ProjectManager>();
      final server = _serverController.text.trim();
      final port = int.tryParse(_portController.text) ?? 8080;

      await projectManager.saveServerSettings(server, port);

      final connection = BlynkConnection(
        serverUrl: server,
        serverPort: port,
      );

      final success = await connection.connect(_authTokenController.text);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: connection,
              child: const ProjectsScreen(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade800,
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
                        Icons.cloud,
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
                        'Connect to your Blynk Server',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _serverController,
                        decoration: InputDecoration(
                          labelText: 'Server Address',
                          hintText: 'localhost or IP address',
                          prefixIcon: const Icon(Icons.dns),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _portController,
                        decoration: InputDecoration(
                          labelText: 'Server Port',
                          hintText: '8080',
                          prefixIcon: const Icon(Icons.settings_ethernet),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _authTokenController,
                        decoration: InputDecoration(
                          labelText: 'Auth Token',
                          hintText: 'Enter your project auth token',
                          prefixIcon: const Icon(Icons.vpn_key),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isConnecting ? null : _connect,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConnecting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'CONNECT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProjectsScreen(),
                            ),
                          );
                        },
                        child: const Text('Browse Projects (Offline)'),
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
