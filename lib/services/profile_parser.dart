import 'dart:convert';
import '../models/dashboard.dart';
import '../models/tab.dart';
import '../models/widget_model.dart';
import '../models/data_stream.dart';

class ProfileParser {
  /// Parse user profile JSON từ server thành danh sách Dashboard
  static List<Dashboard> parseProfileToDashboards(String profileJson) {
    try {
      final data = json.decode(profileJson) as Map<String, dynamic>;
      
      // Server sends {"dashBoards": [...]} directly, not nested in "profile"
      List<dynamic>? dashBoards = data['dashBoards'] as List<dynamic>?;
      
      // Fallback: check if nested in "profile" (old format)
      if (dashBoards == null) {
        final profile = data['profile'] as Map<String, dynamic>?;
        dashBoards = profile?['dashBoards'] as List<dynamic>?;
      }
      
      if (dashBoards == null || dashBoards.isEmpty) {
        return [];
      }
      
      return dashBoards
          .map((d) => _parseDashboard(d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error parsing profile to dashboards: $e');
      return [];
    }
  }
  
  /// Parse user profile JSON từ server thành Dashboard (backward compatible)
  static Dashboard? parseProfile(String profileJson) {
    try {
      final dashboards = parseProfileToDashboards(profileJson);
      if (dashboards.isEmpty) return null;
      
      // Lấy dashboard isActive=true hoặc dashboard đầu tiên
      return dashboards.firstWhere(
        (d) => d.isActive,
        orElse: () => dashboards.first,
      );
    } catch (e) {
      print('Error parsing profile: $e');
      return null;
    }
  }
  
  static Dashboard _parseDashboard(Map<String, dynamic> data) {
    try {
      final id = data['id'] as int;
      final name = data['name'] as String? ?? 'Dashboard';
      
      // Parse devices
      final devicesData = data['devices'] as List<dynamic>?;
      final deviceIds = devicesData?.map((d) => d['id'] as int).toList() ?? [0];
      
      // Parse widgets
      final widgetsData = data['widgets'] as List<dynamic>?;
      
      final allWidgets = widgetsData?.map((w) {
        try {
          return _parseWidget(w as Map<String, dynamic>);
        } catch (e) {
          // Silently skip invalid widgets
          return null;
        }
      }).whereType<WidgetModel>().toList() ?? [];
      
      // Filter out layout widgets (TABS, DEVICE_SELECTOR, etc.)
      final widgets = allWidgets.where((w) => 
        w.type != 'TABS' && 
        w.type != 'DEVICE_SELECTOR' &&
        w.type != 'DEVICE_TILES'
      ).toList();
      
      // Parse tabs từ TABS widget nếu có
      final tabsWidget = allWidgets.firstWhere(
        (w) => w.type == 'TABS',
        orElse: () => WidgetModel(id: -1, type: 'NONE'),
      );
    
    List<TabModel> tabs = [];
    if (tabsWidget.type == 'TABS' && widgetsData != null) {
      // Tìm TABS widget trong raw data để lấy tabs array
      final tabsData = widgetsData.firstWhere(
        (w) => (w as Map<String, dynamic>)['type'] == 'TABS',
        orElse: () => null,
      );
      
      if (tabsData != null) {
        final tabsArray = (tabsData as Map<String, dynamic>)['tabs'] as List<dynamic>?;
        if (tabsArray != null) {
          tabs = tabsArray.asMap().entries.map((entry) {
            final index = entry.key;
            return TabModel(
              id: index,
              label: index == 0 ? 'Main' : 'Tab ${index + 1}',
            );
          }).toList();
        }
      }
    }
    
    // Nếu không có TABS widget, tạo tabs từ unique tabIds
    if (tabs.isEmpty) {
      final tabIds = widgets.map((w) => w.tabId ?? 0).toSet().toList()..sort();
      tabs = tabIds.map((tabId) {
        final tabName = tabId == 0 ? 'Main' : 'Tab ${tabId + 1}';
        return TabModel(id: tabId, label: tabName);
      }).toList();
    }
    
      return Dashboard(
        id: id,
        name: name,
        widgets: widgets,
        tabs: tabs,
        deviceIds: deviceIds,
        isActive: data['isActive'] as bool? ?? true,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing dashboard: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Dashboard data keys: ${data.keys.toList()}');
      rethrow;
    }
  }
  
  static WidgetModel _parseWidget(Map<String, dynamic> data) {
    final type = data['type'] as String;
    final id = data['id'] as int;
    final x = data['x'] as int? ?? 0;
    final y = data['y'] as int? ?? 0;
    final width = data['width'] as int? ?? 1;
    final height = data['height'] as int? ?? 1;
    final color = data['color'] as int?;
    final deviceId = data['deviceId'] as int? ?? 0;
    final tabId = data['tabId'] as int? ?? 0;
    final value = data['value'] as String?;
    
    // Parse label từ các trường có thể
    String? label = data['label'] as String?;
    
    // Parse dataStream (pin info)
    DataStream? dataStream;
    final pin = data['pin'] as int?;
    final pinType = data['pinType'] as String?;
    
    if (pin != null && pin >= 0 && pinType != null) {
      dataStream = DataStream(
        pin: pin,
        pinType: pinType,
        value: value,
        min: (data['min'] as num?)?.toDouble(),
        max: (data['max'] as num?)?.toDouble(),
        label: label,
      );
    }
    
    // Map Blynk widget types to our types
    final mappedType = _mapWidgetType(type);
    
    // Generate default label if not provided
    label ??= _generateDefaultLabel(mappedType, pin, pinType);
    
    return WidgetModel(
      id: id,
      x: x,
      y: y,
      width: width,
      height: height,
      type: mappedType,
      label: label,
      color: color,
      deviceId: deviceId,
      tabId: tabId,
      dataStream: dataStream,
      value: value,
    );
  }
  
  /// Generate default label for widget
  static String _generateDefaultLabel(String type, int? pin, String? pinType) {
    if (pin != null && pin >= 0 && pinType != null) {
      final pinKey = pinType == 'VIRTUAL' ? 'V$pin' 
                   : pinType == 'DIGITAL' ? 'D$pin' 
                   : 'A$pin';
      return '$type ($pinKey)';
    }
    return type;
  }
  
  /// Map Blynk widget type sang widget type của app
  static String _mapWidgetType(String blynkType) {
    switch (blynkType) {
      // Display widgets
      case 'DIGIT4_DISPLAY':
      case 'VALUE_DISPLAY':
      case 'LABELED_VALUE_DISPLAY':
        return 'VALUE_DISPLAY';
      
      case 'GAUGE':
      case 'LEVEL_H':
      case 'LEVEL_V':
        return 'GAUGE';
      
      // Control widgets
      case 'BUTTON':
      case 'STYLED_BUTTON':
        return 'BUTTON';
      
      case 'SLIDER':
      case 'VERTICAL_SLIDER':
        return 'SLIDER';
      
      // Status widgets
      case 'LED':
        return 'LED';
      
      // Text widgets
      case 'TERMINAL':
      case 'LCD':
      case 'TEXT_INPUT':
        return 'TERMINAL';
      
      // Chart widgets
      case 'GRAPH':
      case 'ENHANCED_GRAPH':
      case 'SUPERCHART':
        return 'GRAPH';
      
      // Other
      case 'VIDEO_STREAMING':
        return 'VIDEO';
      
      case 'IMAGE':
      case 'IMAGE_GALLERY':
        return 'IMAGE';
      
      default:
        return blynkType; // Keep original type
    }
  }
}
