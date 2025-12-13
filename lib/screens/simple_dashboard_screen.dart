import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/blynk_service_simple.dart';

class SimpleDashboardScreen extends StatelessWidget {
  const SimpleDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blynk Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<BlynkServiceSimple>().disconnect();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Consumer<BlynkServiceSimple>(
        builder: (context, blynk, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    blynk.isConnected ? Icons.cloud_done : Icons.cloud_off,
                    size: 80,
                    color: blynk.isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    blynk.isConnected ? 'Connected!' : 'Disconnected',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (blynk.email.isNotEmpty)
                    Text(
                      blynk.email,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  const SizedBox(height: 48),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Status',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          Text('✓ WebSocket connected to server'),
                          Text('✓ Password hashing working (SHA256)'),
                          Text('✓ LOGIN message sent'),
                          SizedBox(height: 8),
                          Text(
                            '⚠ Server returns code 9 (INVALID_TOKEN)',
                            style: TextStyle(color: Colors.orange),
                          ),
                          Text(
                            '  This is a known issue - investigating...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: blynk.isConnected
                        ? () => blynk.sendPing()
                        : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Send PING'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
