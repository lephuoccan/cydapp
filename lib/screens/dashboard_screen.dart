import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/project_manager.dart';
import '../services/blynk_connection.dart';
import '../services/auth_service.dart';
import '../widgets/widget_renderer.dart';
import '../widgets/widget_config_dialog.dart';
import '../models/widget_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isEditing = false;

  void _addWidget() {
    showDialog(
      context: context,
      builder: (context) => WidgetConfigDialog(
        onSave: (widget) {
          final projectManager = context.read<ProjectManager>();
          if (projectManager.activeProject != null) {
            final updatedWidgets = [
              ...projectManager.activeProject!.widgets,
              widget,
            ];
            final updatedProject = projectManager.activeProject!.copyWith(
              widgets: updatedWidgets,
            );
            projectManager.updateProject(updatedProject);
          }
        },
      ),
    );
  }

  void _editWidget(WidgetData widget) {
    showDialog(
      context: context,
      builder: (context) => WidgetConfigDialog(
        widget: widget,
        onSave: (updatedWidget) {
          final projectManager = context.read<ProjectManager>();
          if (projectManager.activeProject != null) {
            final updatedWidgets = projectManager.activeProject!.widgets.map((w) {
              return w.id == updatedWidget.id ? updatedWidget : w;
            }).toList();
            final updatedProject = projectManager.activeProject!.copyWith(
              widgets: updatedWidgets,
            );
            projectManager.updateProject(updatedProject);
          }
        },
      ),
    );
  }

  void _deleteWidget(WidgetData widget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Widget'),
        content: Text('Delete "${widget.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final projectManager = context.read<ProjectManager>();
              if (projectManager.activeProject != null) {
                final updatedWidgets = projectManager.activeProject!.widgets
                    .where((w) => w.id != widget.id)
                    .toList();
                final updatedProject = projectManager.activeProject!.copyWith(
                  widgets: updatedWidgets,
                );
                projectManager.updateProject(updatedProject);
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _connectToDevice() async {
    final projectManager = context.read<ProjectManager>();
    final project = projectManager.activeProject;
    
    debugPrint('=== Connect to Device Debug ===');
    debugPrint('Project: ${project?.name}');
    debugPrint('Device ID: ${project?.deviceId}');
    debugPrint('Auth Token: ${project?.authToken}');
    
    if (project == null || project.authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No device connected to this project')),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final device = authService.getDevice(project.deviceId ?? '');
    
    debugPrint('Device found: ${device?.name}');
    
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not found')),
      );
      return;
    }

    // Get server config
    final serverConfig = await authService.getServerConfig();
    final serverIp = serverConfig['ip'] as String;
    final serverPort = serverConfig['port'] as int;
    
    debugPrint('Server IP: $serverIp');
    debugPrint('Server Port: $serverPort');
    debugPrint('Attempting connection...');

    final connection = context.read<BlynkConnection>();
    final success = await connection.connect(
      device.authToken,
      serverIp: serverIp,
      serverPort: serverPort,
    );
    
    debugPrint('Connection result: $success');
    debugPrint('=== End Debug ===');

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ProjectManager>(
          builder: (context, projectManager, child) {
            return Text(projectManager.activeProject?.name ?? 'Dashboard');
          },
        ),
        actions: [
          Consumer<BlynkConnection>(
            builder: (context, connection, child) {
              return IconButton(
                icon: Icon(connection.isConnected ? Icons.cloud_done : Icons.cloud_off),
                onPressed: connection.isConnected ? null : _connectToDevice,
                tooltip: connection.isConnected ? 'Connected' : 'Connect',
              );
            },
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
            tooltip: _isEditing ? 'Done' : 'Edit',
          ),
        ],
      ),
      body: Consumer<ProjectManager>(
        builder: (context, projectManager, child) {
          final project = projectManager.activeProject;
          
          if (project == null) {
            return const Center(
              child: Text('No project selected'),
            );
          }

          if (project.widgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.widgets_outlined,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Widgets',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add widgets',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: project.widgets.length,
            itemBuilder: (context, index) {
              final widget = project.widgets[index];
              return GestureDetector(
                onLongPress: _isEditing ? () => _editWidget(widget) : null,
                child: Stack(
                  children: [
                    WidgetRenderer(widgetData: widget),
                    if (_isEditing)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue.shade100,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                padding: EdgeInsets.zero,
                                onPressed: () => _editWidget(widget),
                              ),
                            ),
                            const SizedBox(width: 4),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.red.shade100,
                              child: IconButton(
                                icon: const Icon(Icons.delete, size: 16),
                                padding: EdgeInsets.zero,
                                onPressed: () => _deleteWidget(widget),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWidget,
        child: const Icon(Icons.add),
      ),
    );
  }
}
