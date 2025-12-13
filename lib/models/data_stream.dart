class DataStream {
  final int pin;
  final String pinType; // "VIRTUAL", "DIGITAL", "ANALOG"
  String? value;
  final double? min;
  final double? max;
  final String? label;

  DataStream({
    required this.pin,
    required this.pinType,
    this.value,
    this.min,
    this.max,
    this.label,
  });

  factory DataStream.fromJson(Map<String, dynamic> json) {
    return DataStream(
      pin: json['pin'] as int,
      pinType: json['pinType'] as String,
      value: json['value'] as String?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pin': pin,
      'pinType': pinType,
      if (value != null) 'value': value,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (label != null) 'label': label,
    };
  }

  String get pinKey {
    switch (pinType) {
      case 'VIRTUAL':
        return 'V$pin';
      case 'DIGITAL':
        return 'D$pin';
      case 'ANALOG':
        return 'A$pin';
      default:
        return 'V$pin';
    }
  }
}
