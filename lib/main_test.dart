import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/blynk_service_simple.dart';

void main() {
  runApp(const BlynkTestApp());
}

class BlynkTestApp extends StatelessWidget {
  const BlynkTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BlynkServiceSimple(),
      child: MaterialApp(
        title: 'Blynk Auth Test',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const TestScreen(),
      ),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _isConnecting = false;
  String _statusMessage = 'Ready to connect';

  Future<void> _testConnection() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting...';
    });

    final service = Provider.of<BlynkServiceSimple>(context, listen: false);
    
    final success = await service.connect(
      '192.168.1.9',
      9443,
      'lephuoccan@gmail.com',
      '111111',
    );

    setState(() {
      _isConnecting = false;
      if (success) {
        _statusMessage = 'Connected successfully! ✓';
      } else {
        _statusMessage = 'Connection failed ✗';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<BlynkServiceSimple>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blynk WebSocket Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                service.isConnected ? Icons.check_circle : Icons.cloud_off,
                size: 80,
                color: service.isConnected ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (service.isConnected)
                Text(
                  'Logged in as: ${service.email}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 48),
              if (!service.isConnected)
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _testConnection,
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isConnecting ? 'Connecting...' : 'Test Connection'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => service.sendPing(),
                      icon: const Icon(Icons.wifi),
                      label: const Text('Send PING'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        service.disconnect();
                        setState(() {
                          _statusMessage = 'Disconnected';
                        });
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Disconnect'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 48),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Configuration:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Server: 192.168.1.9:9443'),
                      Text('Path: /dashws'),
                      Text('User: lephuoccan@gmail.com'),
                      Text('Pass: 111111'),
                      SizedBox(height: 8),
                      Text(
                        'Uses WebSocket with 3-byte header format',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
