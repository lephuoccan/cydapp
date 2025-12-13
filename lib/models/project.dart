import 'dart:convert';
import 'widget_data.dart';

class Project {
  final int id;
  final String name;
  final String theme;
  final bool isActive;
  final List<WidgetData> widgets;
  final String? boardType;
  final String? connectionType;
  final String? deviceId;
  final String? authToken;

  Project({
    required this.id,
    required this.name,
    this.theme = 'Blynk',
    this.isActive = false,
    this.widgets = const [],
    this.boardType,
    this.connectionType,
    this.deviceId,
    this.authToken,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'New Project',
      theme: json['theme'] ?? 'Blynk',
      isActive: json['isActive'] ?? false,
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((w) => WidgetData.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      boardType: json['boardType'],
      connectionType: json['connectionType'],
      deviceId: json['deviceId'],
      authToken: json['authToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'theme': theme,
      'isActive': isActive,
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'boardType': boardType,
      'connectionType': connectionType,
      'deviceId': deviceId,
      'authToken': authToken,
    };
  }

  Project copyWith({
    int? id,
    String? name,
    String? theme,
    bool? isActive,
    List<WidgetData>? widgets,
    String? boardType,
    String? connectionType,
    String? deviceId,
    String? authToken,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      theme: theme ?? this.theme,
      isActive: isActive ?? this.isActive,
      widgets: widgets ?? this.widgets,
      boardType: boardType ?? this.boardType,
      connectionType: connectionType ?? this.connectionType,
      deviceId: deviceId ?? this.deviceId,
      authToken: authToken ?? this.authToken,
    );
  }
}
