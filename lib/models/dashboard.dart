import 'widget_model.dart';
import 'tab.dart';

class Dashboard {
  final int id;
  final String name;
  final List<WidgetModel> widgets;
  final List<TabModel> tabs;
  final List<int> deviceIds;
  final bool isActive;

  Dashboard({
    required this.id,
    required this.name,
    this.widgets = const [],
    this.tabs = const [],
    this.deviceIds = const [],
    this.isActive = false,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Dashboard',
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((w) => WidgetModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      tabs: (json['tabs'] as List<dynamic>?)
              ?.map((t) => TabModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      deviceIds: (json['deviceIds'] as List<dynamic>?)
              ?.map((d) => d as int)
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'tabs': tabs.map((t) => t.toJson()).toList(),
      'deviceIds': deviceIds,
      'isActive': isActive,
    };
  }

  List<WidgetModel> getWidgetsForTab(int tabId) {
    return widgets.where((w) => w.tabId == tabId).toList();
  }

  WidgetModel? getWidgetById(int id) {
    try {
      return widgets.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateWidgetValue(int deviceId, int pin, String pinType, String value) {
    for (var widget in widgets) {
      if (widget.isSamePin(deviceId, pin, pinType)) {
        widget.updateValue(value);
      }
    }
  }
}
