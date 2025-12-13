import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/widget_data.dart';

class ProjectManager extends ChangeNotifier {
  final List<Project> _projects = [];
  Project? _activeProject;
  String _serverUrl = 'localhost';
  int _serverPort = 8080;

  List<Project> get projects => List.unmodifiable(_projects);
  Project? get activeProject => _activeProject;
  String get serverUrl => _serverUrl;
  int get serverPort => _serverPort;

  Future<void> loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getString('projects');
      
      if (projectsJson != null) {
        final List<dynamic> decoded = json.decode(projectsJson);
        _projects.clear();
        _projects.addAll(
          decoded.map((p) => Project.fromJson(p as Map<String, dynamic>))
        );
      }

      // Load server settings
      _serverUrl = prefs.getString('serverUrl') ?? 'localhost';
      _serverPort = prefs.getInt('serverPort') ?? 8080;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading projects: $e');
    }
  }

  Future<void> saveProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_projects.map((p) => p.toJson()).toList());
      await prefs.setString('projects', encoded);
    } catch (e) {
      debugPrint('Error saving projects: $e');
    }
  }

  Future<void> saveServerSettings(String url, int port) async {
    _serverUrl = url;
    _serverPort = port;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverUrl', url);
    await prefs.setInt('serverPort', port);
    
    notifyListeners();
  }

  void addProject(Project project) {
    _projects.add(project);
    saveProjects();
    notifyListeners();
  }

  void updateProject(Project project) {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      if (_activeProject?.id == project.id) {
        _activeProject = project;
      }
      saveProjects();
      notifyListeners();
    }
  }

  void deleteProject(int projectId) {
    _projects.removeWhere((p) => p.id == projectId);
    if (_activeProject?.id == projectId) {
      _activeProject = null;
    }
    saveProjects();
    notifyListeners();
  }

  void setActiveProject(Project? project) {
    _activeProject = project;
    notifyListeners();
  }

  void updateWidgetValue(int widgetId, dynamic value) {
    if (_activeProject == null) return;

    final widgets = _activeProject!.widgets.map((w) {
      if (w.id == widgetId) {
        return w.copyWith(value: value);
      }
      return w;
    }).toList();

    _activeProject = _activeProject!.copyWith(widgets: widgets);
    updateProject(_activeProject!);
  }

  WidgetData? getWidget(int widgetId) {
    if (_activeProject == null) return null;
    
    try {
      return _activeProject!.widgets.firstWhere((w) => w.id == widgetId);
    } catch (e) {
      return null;
    }
  }

  Project createSampleProject() {
    return Project(
      id: DateTime.now().millisecondsSinceEpoch,
      name: 'Sample Project',
      theme: 'Blynk',
      isActive: false,
      widgets: [
        WidgetData(
          id: 1,
          type: WidgetType.button,
          x: 0,
          y: 0,
          width: 2,
          height: 1,
          label: 'LED Control',
          pin: 1,
          pinType: 'virtual',
          mode: 'switch',
          value: 0,
          color: 0xFF4CAF50,
        ),
        WidgetData(
          id: 2,
          type: WidgetType.slider,
          x: 0,
          y: 1,
          width: 2,
          height: 1,
          label: 'Brightness',
          pin: 2,
          pinType: 'virtual',
          value: 128,
          min: 0,
          max: 255,
          color: 0xFF2196F3,
        ),
        WidgetData(
          id: 3,
          type: WidgetType.display,
          x: 0,
          y: 2,
          width: 2,
          height: 1,
          label: 'Temperature',
          pin: 3,
          pinType: 'virtual',
          value: '25.5',
          color: 0xFFFF9800,
        ),
        WidgetData(
          id: 4,
          type: WidgetType.gauge,
          x: 0,
          y: 3,
          width: 2,
          height: 2,
          label: 'Humidity',
          pin: 4,
          pinType: 'virtual',
          value: 60,
          min: 0,
          max: 100,
          color: 0xFF03A9F4,
        ),
      ],
    );
  }
}
