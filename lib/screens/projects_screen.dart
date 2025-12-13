import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/project_manager.dart';
import '../services/auth_service.dart';
import '../models/project.dart';
import '../models/device.dart';
import 'dashboard_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectManager>().loadProjects();
    });
  }

  void _createSampleProject() {
    final projectManager = context.read<ProjectManager>();
    final project = projectManager.createSampleProject();
    projectManager.addProject(project);
  }

  void _createNewProject() {
    final nameController = TextEditingController();
    Device? selectedDevice;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final authService = context.read<AuthService>();
          final devices = authService.devices;
          
          return AlertDialog(
            title: const Text('New Project'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'Enter project name',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                if (devices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'No devices available. Create a device first in the Devices tab.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  )
                else
                  DropdownButtonFormField<Device>(
                    value: selectedDevice,
                    decoration: const InputDecoration(
                      labelText: 'Select Device',
                      border: OutlineInputBorder(),
                    ),
                    items: devices.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text(device.name),
                      );
                    }).toList(),
                    onChanged: (device) {
                      setState(() => selectedDevice = device);
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && selectedDevice != null) {
                    final project = Project(
                      id: DateTime.now().millisecondsSinceEpoch,
                      name: nameController.text,
                      widgets: [],
                      deviceId: selectedDevice!.id,
                      authToken: selectedDevice!.authToken,
                    );
                    context.read<ProjectManager>().addProject(project);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('CREATE'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteProject(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProjectManager>().deleteProject(project.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Create Sample Project',
            onPressed: _createSampleProject,
          ),
        ],
      ),
      body: Consumer<ProjectManager>(
        builder: (context, projectManager, child) {
          if (projectManager.projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Projects Yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a new project to get started',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createSampleProject,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Sample Project'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: projectManager.projects.length,
            itemBuilder: (context, index) {
              final project = projectManager.projects[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    projectManager.setActiveProject(project);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.dashboard,
                              size: 48,
                              color: Colors.blue.shade400,
                            ),
                            const Spacer(),
                            Text(
                              project.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${project.widgets.length} widgets',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteProject(project);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}
