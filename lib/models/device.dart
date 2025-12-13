class Device {
  final String id;
  final String name;
  final String authToken;
  final String boardType;
  final String connectionType;
  final bool isOnline;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.name,
    required this.authToken,
    this.boardType = 'Generic Board',
    this.connectionType = 'WiFi',
    this.isOnline = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Device',
      authToken: json['token'] ?? json['authToken'] ?? '',
      boardType: json['boardType'] ?? 'Generic Board',
      connectionType: json['connectionType'] ?? 'WiFi',
      isOnline: json['isOnline'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'authToken': authToken,
      'boardType': boardType,
      'connectionType': connectionType,
      'isOnline': isOnline,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? authToken,
    String? boardType,
    String? connectionType,
    bool? isOnline,
    DateTime? createdAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      authToken: authToken ?? this.authToken,
      boardType: boardType ?? this.boardType,
      connectionType: connectionType ?? this.connectionType,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    
    for (int i = 0; i < 32; i++) {
      final index = (random + i) % chars.length;
      buffer.write(chars[index]);
    }
    
    return buffer.toString();
  }
}
