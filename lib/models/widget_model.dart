import 'data_stream.dart';

class WidgetModel {
  final int id;
  final int x;
  final int y;
  final int width;
  final int height;
  final String type;
  final String? label;
  final int? color;
  final int? deviceId;
  final int? tabId;
  final DataStream? dataStream;
  String? value;

  WidgetModel({
    required this.id,
    this.x = 0,
    this.y = 0,
    this.width = 1,
    this.height = 1,
    required this.type,
    this.label,
    this.color,
    this.deviceId,
    this.tabId,
    this.dataStream,
    this.value,
  });

  factory WidgetModel.fromJson(Map<String, dynamic> json) {
    return WidgetModel(
      id: json['id'] as int,
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      width: json['width'] as int? ?? 1,
      height: json['height'] as int? ?? 1,
      type: json['type'] as String,
      label: json['label'] as String?,
      color: json['color'] as int?,
      deviceId: json['deviceId'] as int?,
      tabId: json['tabId'] as int?,
      dataStream: json['pin'] != null 
          ? DataStream.fromJson(json['pin'] as Map<String, dynamic>)
          : null,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'type': type,
      if (label != null) 'label': label,
      if (color != null) 'color': color,
      if (deviceId != null) 'deviceId': deviceId,
      if (tabId != null) 'tabId': tabId,
      if (dataStream != null) 'pin': dataStream!.toJson(),
      if (value != null) 'value': value,
    };
  }

  bool isSamePin(int deviceId, int pin, String pinType) {
    return this.deviceId == deviceId &&
        dataStream != null &&
        dataStream!.pin == pin &&
        dataStream!.pinType == pinType;
  }

  void updateValue(String newValue) {
    value = newValue;
    if (dataStream != null) {
      dataStream!.value = newValue;
    }
  }
}
