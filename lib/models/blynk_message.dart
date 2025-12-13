class BlynkMessage {
  final int commandId;
  final int messageId;
  final List<String> parameters;

  BlynkMessage({
    required this.commandId,
    required this.messageId,
    required this.parameters,
  });

  // Blynk protocol message structure: [commandId, messageId, length/responseCode, body]
  static BlynkMessage parse(List<int> data) {
    if (data.length < 5) {
      throw Exception('Invalid message length');
    }

    final commandId = data[0];
    final messageId = (data[1] << 8) | data[2];
    
    // Response messages (command 0) have responseCode instead of length
    if (commandId == 0) {
      final responseCode = (data[3] << 8) | data[4];
      return BlynkMessage(
        commandId: commandId,
        messageId: messageId,
        parameters: [responseCode.toString()],
      );
    }
    
    // Regular messages have length + body
    final length = (data[3] << 8) | data[4];
    final body = length > 0 && data.length >= (5 + length)
        ? String.fromCharCodes(data.sublist(5, 5 + length))
        : '';
    final parameters = body.isEmpty ? <String>[] : body.split('\0');

    return BlynkMessage(
      commandId: commandId,
      messageId: messageId,
      parameters: parameters,
    );
  }

  List<int> encode() {
    final bodyParts = parameters.join('\0');
    final bodyBytes = bodyParts.codeUnits;
    final length = bodyBytes.length;

    return [
      commandId,
      (messageId >> 8) & 0xFF,
      messageId & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
      ...bodyBytes,
    ];
  }

  @override
  String toString() {
    return 'BlynkMessage(cmd: $commandId, msgId: $messageId, params: $parameters)';
  }
}

// Blynk command IDs - from Blynk server Command.java
class BlynkCommand {
  static const int response = 0;
  
  // App commands
  static const int register = 1;
  static const int login = 2;
  static const int redeem = 3;
  static const int hardwareConnected = 4;
  static const int ping = 6;
  static const int activateDashboard = 7;
  static const int deactivateDashboard = 8;
  static const int refreshToken = 9;
  
  // Hardware commands
  static const int tweet = 12;
  static const int email = 13;
  static const int pushNotification = 14;
  static const int bridge = 15;
  static const int hardwareSync = 16;
  static const int blynkInternal = 17;
  static const int sms = 18;
  static const int setWidgetProperty = 19;
  static const int hardware = 20;
  
  // App commands
  static const int createDash = 21;
  static const int updateDash = 22;
  static const int deleteDash = 23;
  static const int loadProfileGzipped = 24;
  static const int appSync = 25;
  static const int sharing = 26;
  static const int addPushToken = 27;
  static const int exportGraphData = 28;
  static const int hardwareLogin = 29;
  
  // Sharing commands
  static const int getShareToken = 30;
  static const int refreshShareToken = 31;
  static const int shareLogin = 32;
  
  // Widget commands
  static const int createWidget = 33;
  static const int updateWidget = 34;
  static const int deleteWidget = 35;
  
  // Energy commands
  static const int getEnergy = 36;
  static const int addEnergy = 37;
  
  static const int updateProjectSettings = 38;
  static const int assignToken = 39;
  static const int getServer = 40;
  static const int connectRedirect = 41;
  
  // Device commands
  static const int createDevice = 42;
  static const int updateDevice = 43;
  static const int deleteDevice = 44;
  static const int getDevices = 45;
}

// Hardware commands
class HardwareCommand {
  static const String digitalWrite = 'dw';
  static const String analogWrite = 'aw';
  static const String digitalRead = 'dr';
  static const String analogRead = 'ar';
  static const String virtualWrite = 'vw';
  static const String virtualRead = 'vr';
  static const String pinModeChange = 'pm';
}
