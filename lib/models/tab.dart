class TabModel {
  final int id;
  final String label;

  TabModel({
    required this.id,
    required this.label,
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
