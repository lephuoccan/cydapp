enum WidgetType {
  button,
  slider,
  display,
  graph,
  led,
  gauge,
  terminal,
  joystick,
  stepControl,
  rgbPicker,
  timer,
  video,
  webView,
  notification,
  twitter,
  email,
  rtc,
  bridge,
  eventor,
  lcd,
  table,
  map,
  timeInput,
  segmentedSwitch,
  tabs,
  menu,
  zeroGram,
  image,
  enhancedGraph,
  superChart,
  webhook,
  unknown,
}

class WidgetData {
  final int id;
  final WidgetType type;
  final int x;
  final int y;
  final int width;
  final int height;
  final int tabId;
  final String label;
  final int? pin;
  final String? pinType; // digital, analog, virtual
  final String? mode; // push, switch for button
  final dynamic value;
  final dynamic min;
  final dynamic max;
  final int? color;
  final Map<String, dynamic>? settings;

  WidgetData({
    required this.id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 2,
    this.height = 2,
    this.tabId = 0,
    this.label = '',
    this.pin,
    this.pinType,
    this.mode,
    this.value,
    this.min,
    this.max,
    this.color,
    this.settings,
  });

  factory WidgetData.fromJson(Map<String, dynamic> json) {
    return WidgetData(
      id: json['id'] ?? 0,
      type: _parseWidgetType(json['type']),
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      width: json['width'] ?? 2,
      height: json['height'] ?? 2,
      tabId: json['tabId'] ?? 0,
      label: json['label'] ?? '',
      pin: json['pin'],
      pinType: json['pinType'],
      mode: json['mode'],
      value: json['value'],
      min: json['min'],
      max: json['max'],
      color: json['color'],
      settings: json['settings'],
    );
  }

  static WidgetType _parseWidgetType(dynamic typeValue) {
    if (typeValue is String) {
      try {
        return WidgetType.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == typeValue.toLowerCase(),
          orElse: () => WidgetType.unknown,
        );
      } catch (e) {
        return WidgetType.unknown;
      }
    } else if (typeValue is int) {
      // Map Blynk widget type IDs to our enum
      switch (typeValue) {
        case 1:
          return WidgetType.button;
        case 2:
          return WidgetType.slider;
        case 3:
          return WidgetType.display;
        case 4:
          return WidgetType.graph;
        case 5:
          return WidgetType.led;
        case 6:
          return WidgetType.gauge;
        case 7:
          return WidgetType.terminal;
        case 8:
          return WidgetType.joystick;
        default:
          return WidgetType.unknown;
      }
    }
    return WidgetType.unknown;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'tabId': tabId,
      'label': label,
      'pin': pin,
      'pinType': pinType,
      'mode': mode,
      'value': value,
      'min': min,
      'max': max,
      'color': color,
      'settings': settings,
    };
  }

  WidgetData copyWith({
    int? id,
    WidgetType? type,
    int? x,
    int? y,
    int? width,
    int? height,
    int? tabId,
    String? label,
    int? pin,
    String? pinType,
    String? mode,
    dynamic value,
    dynamic min,
    dynamic max,
    int? color,
    Map<String, dynamic>? settings,
  }) {
    return WidgetData(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      tabId: tabId ?? this.tabId,
      label: label ?? this.label,
      pin: pin ?? this.pin,
      pinType: pinType ?? this.pinType,
      mode: mode ?? this.mode,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
      color: color ?? this.color,
      settings: settings ?? this.settings,
    );
  }
}
