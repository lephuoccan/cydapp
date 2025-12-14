class TabModel {
  final int id;
  final String label;
  int? selectedDeviceId;

  TabModel({
    required this.id,
    required this.label,
    this.selectedDeviceId,
  });

  factory TabModel.fromJson(Map<String, dynamic> json) {
    return TabModel(
      id: json['id'] as int? ?? 0,
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
    };
  }
}
