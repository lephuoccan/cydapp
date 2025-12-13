/// Blynk Protocol Constants
/// Reference: https://github.com/lephuoccan/iotserver
/// Based on server/core/src/main/java/cc/blynk/server/core/protocol/enums/
///
/// ========================================
/// TESTED & VERIFIED WORKFLOWS
/// ========================================
///
/// ✅ 1. LOGIN FLOW (WebSocket /dashws)
/// -----------------------------------
/// Server: 192.168.1.9:9443
/// Path: wss://192.168.1.9:9443/dashws
/// 
/// Message Format (WebSocket):
/// [Command(1) | MessageId(2) | Body(variable)]
/// 
/// Login Request:
/// - Command: BlynkCommand.login (2)
/// - MessageId: 0x0001
/// - Body: "email\0passwordHash\0os\0version\0appName"
///   Example: "lephuoccan@gmail.com\0[SHA256(password+salt)]\0web\01.0.0\0Blynk"
/// 
/// Password Hash Algorithm:
/// 1. salt = SHA256(email.toLowerCase())
/// 2. combined = password + salt
/// 3. hash = SHA256(combined)
/// 4. encoded = Base64(hash)
/// 
/// Login Response:
/// - Command: BlynkCommand.response (0)
/// - MessageId: 0x0001 (matches request)
/// - Response Code (4 bytes): 
///   * 200 (BlynkStatus.ok) = Success
///   * 9 (BlynkStatus.invalidToken) = Wrong credentials
/// 
/// ✅ 2. PING HEARTBEAT (Keep-Alive)
/// ----------------------------------
/// Purpose: Prevent server timeout (hard.socket.idle.timeout)
/// 
/// Timing:
/// - Interval: 10 seconds (BlynkProtocol.pingInterval)
/// - Server Timeout: pingInterval * 2.3 = ~23 seconds
/// - Safety Margin: 13 seconds before timeout
/// 
/// Ping Request:
/// - Command: BlynkCommand.ping (6)
/// - MessageId: timestamp & 0xFFFF
/// - No body (3 bytes total)
/// 
/// Ping Response:
/// - Command: BlynkCommand.response (0)
/// - Response Code: 200 (OK)
/// 
/// Auto-Reconnect:
/// - On disconnect: wait 5 seconds → retry with saved credentials
/// - On success: restart ping timer
/// - Infinite retry loop
/// 
/// ✅ 3. VIRTUAL PIN READ (Hardware Data from ESP32)
/// --------------------------------------------------
/// Direction: ESP32 → Server → Flutter App
/// 
/// Message Format:
/// - Command: BlynkCommand.hardware (20)
/// - MessageId: varies
/// - Body: "dashId-deviceId\0vw\0pin\0value"
///   Example: "1683803793-0\0vw\00\0325349"
///   
/// Body Structure:
/// - Part[0]: "1683803793-0" (dashId-deviceId)
/// - Part[1]: "vw" (BlynkPinCommand.virtualWrite)
/// - Part[2]: "0" (pin number)
/// - Part[3]: "325349" (pin value)
/// 
/// Separator: '\0' (BlynkProtocol.bodySeparator)
/// 
/// Decoding Logic:
/// 1. Receive Command 20 (HARDWARE)
/// 2. Extract body from bytes[3:]
/// 3. Split by '\0' separator
/// 4. Parse: cmd = parts[1]
/// 5. If cmd == "vw": Virtual Write
///    If cmd == "dw": Digital Write  
///    If cmd == "aw": Analog Write
/// 6. Store: pinValues['V0'] = '325349'
/// 7. Notify listeners → UI updates
/// 
/// Real Test Data (Verified Working):
/// - V0 receiving continuous data from ESP32
/// - Values: 237174, 238176, 239178... (incrementing)
/// - Update rate: ~1-2 seconds per message
/// - Stable connection maintained 10+ minutes
/// 
/// ✅ 4. VIRTUAL PIN WRITE (Send to ESP32)
/// ----------------------------------------
/// Direction: Flutter App → Server → ESP32
/// 
/// Message Format:
/// - Command: BlynkCommand.hardware (20)
/// - MessageId: timestamp & 0xFFFF
/// - Body: "dashId-deviceId\0vw\0pin\0value"
///   Example: "1683803793-0\0vw\01\0100"
/// 
/// Method: BlynkServiceSimple.sendVirtualPin(pin, value)
/// Usage: blynkService.sendVirtualPin(1, "888")
/// Result: ESP32 receives in BLYNK_WRITE(V1) handler
/// 
/// ========================================
/// PROTOCOL NOTES
/// ========================================
/// 
/// WebSocket vs Hardware Protocol:
/// - WebSocket: 3-byte header [Cmd|MsgId(2)]
/// - Hardware: 5-byte header [Cmd|MsgId(2)|Length(2)]
/// - Mobile App: 7-byte header [Cmd|MsgId(2)|Length(4)]
/// 
/// Credentials (Test Environment):
/// - Email: lephuoccan@gmail.com
/// - Password: 111111
/// - DashboardId: 1683803793
/// - DeviceId: 0
/// 
/// ========================================

/// Command codes used in Blynk protocol
class BlynkCommand {
  BlynkCommand._();

  // Response
  static const int response = 0;

  // App commands
  static const int register = 1;
  static const int login = 2;
  static const int redeem = 3;
  static const int hardwareConnected = 4;

  // Common commands
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

  // Dashboard commands
  static const int createDash = 21;
  static const int updateDash = 22;
  static const int deleteDash = 23;
  static const int loadProfileGzipped = 24;
  static const int appSync = 25;
  static const int sharing = 26;
  static const int addPushToken = 27;
  static const int exportGraphData = 28;

  // Auth commands
  static const int hardwareLogin = 29;
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

  // Settings
  static const int updateProjectSettings = 38;
  static const int assignToken = 39;
  static const int getServer = 40;
  static const int connectRedirect = 41;

  // Device commands
  static const int createDevice = 42;
  static const int updateDevice = 43;
  static const int deleteDevice = 44;
  static const int getDevices = 45;

  // Tag commands
  static const int createTag = 46;
  static const int updateTag = 47;
  static const int deleteTag = 48;
  static const int getTags = 49;
  static const int mobileGetDevice = 50;

  static const int updateFace = 51;

  // Protocol extensions
  static const int webSockets = 52;
  static const int eventor = 53;
  static const int webHooks = 54;

  // App management
  static const int createApp = 55;
  static const int updateApp = 56;
  static const int deleteApp = 57;
  static const int getProjectByToken = 58;
  static const int emailQr = 59;

  // Graph data
  static const int getEnhancedGraphData = 60;
  static const int deleteEnhancedGraphData = 61;

  // Clone/Provision
  static const int getCloneCode = 62;
  static const int getProjectByCloneCode = 63;

  // Additional hardware
  static const int hardwareLogEvent = 64;
  static const int hardwareResendFromBluetooth = 65;
  static const int logout = 66;

  // Tile templates
  static const int createTileTemplate = 67;
  static const int updateTileTemplate = 68;
  static const int deleteTileTemplate = 69;
  static const int getWidget = 70;
  static const int deviceOffline = 71;
  static const int outdatedAppNotification = 72;
  static const int trackDevice = 73;
  static const int getProvisionToken = 74;
  static const int resolveEvent = 75;
  static const int deleteDeviceData = 76;

  // Reports
  static const int createReport = 77;
  static const int updateReport = 78;
  static const int deleteReport = 79;
  static const int exportReport = 80;

  static const int resetPassword = 81;

  // HTTP endpoints (for stats only)
  static const int httpIsHardwareConnected = 82;
  static const int httpIsAppConnected = 83;
  static const int httpGetPinData = 84;
  static const int httpUpdatePinData = 85;
  static const int httpNotify = 86;
  static const int httpEmail = 87;
  static const int httpGetProject = 88;
  static const int httpQr = 89;
  static const int httpGetHistoryData = 90;
  static const int httpStartOta = 91;
  static const int httpStopOta = 92;
  static const int httpClone = 93;
  static const int httpTotal = 94;

  /// Get human-readable command name
  static String getName(int command) {
    switch (command) {
      case response: return 'Response';
      case register: return 'Register';
      case login: return 'Login';
      case ping: return 'Ping';
      case hardware: return 'Hardware';
      case activateDashboard: return 'ActivateDashboard';
      case deactivateDashboard: return 'DeactivateDashboard';
      case hardwareLogin: return 'HardwareLogin';
      case tweet: return 'Tweet';
      case email: return 'Email';
      case pushNotification: return 'PushNotification';
      case bridge: return 'Bridge';
      case hardwareSync: return 'HardwareSync';
      case blynkInternal: return 'BlynkInternal';
      case sms: return 'SMS';
      case setWidgetProperty: return 'SetWidgetProperty';
      case appSync: return 'AppSync';
      default: return 'Command($command)';
    }
  }
}

/// Response status codes
class BlynkStatus {
  BlynkStatus._();

  static const int ok = 200;
  static const int quotaLimit = 1;
  static const int illegalCommand = 2;
  static const int userNotRegistered = 3;
  static const int userAlreadyRegistered = 4;
  static const int userNotAuthenticated = 5;
  static const int notAllowed = 6;
  static const int deviceNotInNetwork = 7;
  static const int noActiveDashboard = 8;
  static const int invalidToken = 9;
  static const int illegalCommandBody = 11;
  static const int notificationInvalidBody = 13;
  static const int notificationNotAuthorized = 14;
  static const int notificationError = 15;
  static const int blynkTimeout = 16;
  static const int noData = 17;
  static const int deviceWentOffline = 18;
  static const int serverError = 19;
  static const int notSupportedVersion = 20;
  static const int energyLimit = 21;
  static const int facebookUserLoginWithPass = 22;

  /// Get human-readable status message
  static String getMessage(int code) {
    switch (code) {
      case ok:
        return 'OK - Success';
      case quotaLimit:
        return 'Quota limit exceeded';
      case illegalCommand:
        return 'Illegal command';
      case userNotRegistered:
        return 'User not registered';
      case userAlreadyRegistered:
        return 'User already registered';
      case userNotAuthenticated:
        return 'User not authenticated';
      case notAllowed:
        return 'Operation not allowed';
      case deviceNotInNetwork:
        return 'Device not in network';
      case noActiveDashboard:
        return 'No active dashboard';
      case invalidToken:
        return 'Invalid token - Wrong email or password';
      case illegalCommandBody:
        return 'Illegal command body';
      case notificationInvalidBody:
        return 'Notification invalid body';
      case notificationNotAuthorized:
        return 'Notification not authorized';
      case notificationError:
        return 'Notification error';
      case blynkTimeout:
        return 'Connection timeout';
      case noData:
        return 'No data available';
      case deviceWentOffline:
        return 'Device went offline';
      case serverError:
        return 'Internal server error';
      case notSupportedVersion:
        return 'Version not supported';
      case energyLimit:
        return 'Energy limit reached';
      case facebookUserLoginWithPass:
        return 'Facebook user must login with Facebook';
      default:
        return 'Unknown status code: $code';
    }
  }
}

/// Hardware pin commands
class BlynkPinCommand {
  BlynkPinCommand._();

  /// Virtual Write (vw) - Write to virtual pin
  static const String virtualWrite = 'vw';
  
  /// Virtual Read (vr) - Read virtual pin
  static const String virtualRead = 'vr';
  
  /// Digital Write (dw) - Write to digital pin
  static const String digitalWrite = 'dw';
  
  /// Digital Read (dr) - Read digital pin
  static const String digitalRead = 'dr';
  
  /// Analog Write (aw) - Write to analog pin (PWM)
  static const String analogWrite = 'aw';
  
  /// Analog Read (ar) - Read analog pin
  static const String analogRead = 'ar';
  
  /// Pin Mode (pm) - Set pin mode
  static const String pinMode = 'pm';
}

/// Protocol configuration
class BlynkProtocol {
  BlynkProtocol._();

  /// WebSocket protocol uses 3-byte header (no length field)
  static const int websocketHeaderSize = 3;
  
  /// Mobile/Hardware protocol uses 5-byte header (with length field)
  static const int hardwareHeaderSize = 5;
  
  /// Mobile app protocol uses 7-byte header (with 4-byte length)
  static const int mobileHeaderSize = 7;
  
  /// Message body separator (null character)
  static const String bodySeparator = '\u0000';
  
  /// Default ping interval (milliseconds)
  static const int pingInterval = 10000;
  
  /// Server timeout multiplier
  static const double heartbeatTimeoutMultiplier = 2.3;
  
  /// Maximum message size
  static const int maxMessageSize = 32768; // 32KB
}
