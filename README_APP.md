# CYDS - Blynk Client App

Ứng dụng client đa nền tảng cho Blynk IoT Server.

## Tính năng

✅ **Đã hoàn thành:**
- Login với email/password (WebSocket Secure)
- Device connection với auth token
- Real-time pin value updates (Virtual, Digital, Analog)
- Send commands to hardware (Virtual Write)
- Cross-platform: Android, iOS, Web, Desktop

🚧 **Đang phát triển:**
- Dashboard UI với widgets
- Project management
- Device management
- Widget configuration

## Cài đặt

### Yêu cầu
- Flutter SDK 3.10.1+
- Blynk Server đang chạy tại `192.168.1.9:9443`

### Chạy app

#### 1. Device Test Screen (Đơn giản nhất)
Test kết nối device với auth token:

```bash
flutter run -d chrome -t lib/main_device_test.dart
```

**Cách dùng:**
1. Mở Chrome, accept SSL certificate: https://192.168.1.9:9443
2. Nhập Server IP: `192.168.1.9`
3. Nhập Port: `9443`
4. Nhập Device Auth Token (lấy từ web dashboard)
5. Click **CONNECT**
6. Xem pin values cập nhật real-time
7. Click **SEND VIRTUAL WRITE** để gửi lệnh

#### 2. Full App (Login + Dashboard)
```bash
flutter run -d chrome -t lib/main.dart
```

Login:
- Email: `lephuoccan@gmail.com`
- Password: `111111`

#### 3. Simple Test App
```bash
flutter run -d chrome -t lib/main_test.dart
```

## Cấu trúc Project

```
lib/
├── main.dart                      # Full app
├── main_test.dart                 # Simple test
├── main_device_test.dart          # Device connection test
├── screens/
│   ├── auth_screen.dart           # Login/Register
│   ├── device_test_screen.dart    # Device test UI
│   ├── dashboard_screen.dart      # Dashboard
│   └── ...
├── services/
│   ├── auth_service.dart          # User authentication
│   ├── blynk_connection.dart      # Device WebSocket connection
│   └── ...
└── models/
    ├── user.dart
    ├── device.dart
    └── ...
```

## Giao thức WebSocket

### User Login (App)
- **Path**: `/dashws`
- **Command**: `29` (APP_LOGIN)
- **Format**: 3-byte header `[command | messageId(2) | body]`
- **Body**: `email|passwordHash|web|1.0.0|Blynk`
- **Response**: Code `200` = OK

### Hardware Login (Device)
- **Path**: `/dashws`
- **Command**: `2` (LOGIN)
- **Format**: 3-byte header `[command | messageId(2) | authToken]`
- **Response**: Code `200` = OK

### Hardware Command
- **Command**: `20` (HARDWARE)
- **Body format**: `command\0pin\0value`
- **Commands**:
  - `vw` - Virtual Write: `vw\0pin\0value`
  - `vr` - Virtual Read: `vr\0pin`
  - `dw` - Digital Write: `dw\0pin\0value`
  - `aw` - Analog Write: `aw\0pin\0value`

### Ping/Keep-alive
- **Command**: `6` (PING)
- **Interval**: 10 seconds
- **Body**: Empty

## Hướng dẫn chi tiết

- [WEB_SETUP.md](WEB_SETUP.md) - Setup SSL certificate cho web
- [DEVICE_SETUP.md](DEVICE_SETUP.md) - Hướng dẫn test device connection

## ESP32 Example Code

```cpp
#define BLYNK_PRINT Serial
#include <WiFi.h>
#include <BlynkSimpleEsp32_SSL.h>

char auth[] = "YOUR_DEVICE_AUTH_TOKEN";
char ssid[] = "YOUR_WIFI_SSID";
char pass[] = "YOUR_WIFI_PASSWORD";

char server[] = "192.168.1.9";
uint16_t port = 9443;

BLYNK_WRITE(V0) {
  int value = param.asInt();
  Serial.printf("V0: %d\n", value);
}

void setup() {
  Serial.begin(115200);
  Blynk.begin(auth, ssid, pass, server, port);
}

void loop() {
  Blynk.run();
  
  // Send sensor data
  Blynk.virtualWrite(V1, analogRead(A0));
  delay(1000);
}
```

## Troubleshooting

### SSL Certificate Error
Web app cần accept certificate trước:
1. Mở tab mới: `https://192.168.1.9:9443`
2. Click "Advanced" → "Proceed to 192.168.1.9 (unsafe)"
3. Quay lại app và thử lại

### Connection Failed
- Kiểm tra server đang chạy
- Kiểm tra firewall cho port 9443
- Thử ping `192.168.1.9`

### Code 9 (INVALID_TOKEN)
- Device auth token sai
- Tạo lại device trong web dashboard
- Copy token chính xác

### Không nhận được pin values
- Device chưa gửi data
- Kiểm tra ESP32 code có `Blynk.virtualWrite()`
- Sync lại với `syncWidget(pin)`

## License

MIT
