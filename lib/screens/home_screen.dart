import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/project_manager.dart';
import 'devices_screen.dart';
import 'projects_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectManager>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const ProjectsScreen(),
      const DevicesScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthService>(
          builder: (context, authService, child) {
            return Text('Hello, ${authService.currentUser?.name ?? "User"}');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
        ],
      ),
    );
  }
}
