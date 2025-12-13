import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/device.dart';
import '../services/project_manager.dart';
import '../models/project.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  void _showCreateDeviceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final boardController = TextEditingController(text: 'Generic Board');
    final connectionController = TextEditingController(text: 'WiFi');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'My Arduino',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: boardController,
              decoration: const InputDecoration(
                labelText: 'Board Type',
                hintText: 'Arduino Uno, ESP32, etc',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: connectionController,
              decoration: const InputDecoration(
                labelText: 'Connection Type',
                hintText: 'WiFi, Ethernet, etc',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final authService = context.read<AuthService>();
                final device = await authService.createDevice(
                  nameController.text,
                  boardType: boardController.text,
                  connectionType: connectionController.text,
                );

                // Auto-create project for this device
                final projectManager = context.read<ProjectManager>();
                final project = Project(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: device.name,
                  deviceId: device.id,
                  authToken: device.authToken,
                  boardType: device.boardType,
                  connectionType: device.connectionType,
                  widgets: [],
                );
                projectManager.addProject(project);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Device "${device.name}" created!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  void _showDeviceDetails(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.devices, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(device.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Board Type', device.boardType),
            _buildInfoRow('Connection', device.connectionType),
            _buildInfoRow('Status', device.isOnline ? 'Online' : 'Offline'),
            const Divider(height: 24),
            const Text(
              'Auth Token',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      device.authToken,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: device.authToken));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Token copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDevice(context, device);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteDevice(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.deleteDevice(device.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Devices Yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a device to get started',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDeviceDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Device'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: authService.devices.length,
            itemBuilder: (context, index) {
              final device = authService.devices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: device.isOnline
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    child: Icon(
                      Icons.memory,
                      color: device.isOnline
                          ? Colors.green.shade800
                          : Colors.grey.shade600,
                    ),
                  ),
                  title: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${device.boardType} • ${device.connectionType}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: device.isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: device.isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showDeviceDetails(context, device),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDeviceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
