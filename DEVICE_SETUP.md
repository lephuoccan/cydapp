# Hướng Dẫn Test Device Connection

## Bước 1: Tạo Device Token từ Web Dashboard

1. Mở trình duyệt, truy cập: `https://192.168.1.9:9443`
2. Chấp nhận certificate (Advanced → Proceed)
3. Login với tài khoản: `lephuoccan@gmail.com` / `111111`
4. Tạo project mới hoặc mở project có sẵn
5. Add device → Copy **Auth Token** (dạng: `abc123def456...`)

## Bước 2: Test Connection

### Cách 1: Dùng Device Test Screen

```bash
flutter run -d chrome -t lib/main_device_test.dart
```

Nhập thông tin:
- **Server IP**: `192.168.1.9`
- **Port**: `9443`
- **Auth Token**: Token vừa copy từ web dashboard

Click **CONNECT** để kết nối.

### Cách 2: Dùng ESP32/Arduino Code

```cpp
#define BLYNK_PRINT Serial
#include <WiFi.h>
#include <BlynkSimpleEsp32_SSL.h>

char auth[] = "YOUR_DEVICE_TOKEN_HERE";
char ssid[] = "YOUR_WIFI_SSID";
char pass[] = "YOUR_WIFI_PASSWORD";

// Custom server
char server[] = "192.168.1.9";
uint16_t port = 9443;

void setup() {
  Serial.begin(115200);
  Blynk.begin(auth, ssid, pass, server, port);
}

void loop() {
  Blynk.run();
}
```

## Bước 3: Test Virtual Pins

Sau khi connected:

1. Trong Device Test Screen, click **SEND VIRTUAL WRITE**
2. Nhập:
   - **Pin**: `0` (cho V0)
   - **Value**: `123` hoặc bất kỳ giá trị nào
3. Click **SEND**

Kiểm tra terminal sẽ thấy log:
```
📤 Virtual write V0 = 123
```

## Bước 4: Nhận Data từ Device

Nếu có ESP32 đang chạy và gửi data:

```cpp
// Trong code ESP32
Blynk.virtualWrite(V1, sensor_value);
```

App sẽ nhận và hiển thị trong **Pin Values**:
```
V1: sensor_value
```

## Lưu Ý

### SSL Certificate
- Port 9443 dùng WebSocket Secure (wss://)
- Phải accept certificate trong Chrome trước khi test
- Mở tab mới: `https://192.168.1.9:9443` → Accept

### Device Token vs User Token
- **User Token**: Dùng để login vào web dashboard (email + password)
- **Device Token**: Dùng để device/ESP32 kết nối (auth token của project)
- **Không thể dùng user token cho device!**

### Ports
- **9443**: App connection (WebSocket Secure - wss://)
- **8080**: Device connection (TCP hoặc WebSocket)
- App dùng `/dashws` path, device có thể dùng `/websocket`

## Troubleshooting

### Connection Failed
1. Kiểm tra server đang chạy: `C:\cydc\cyds\blynk-server\server.jar`
2. Kiểm tra firewall cho port 9443
3. Đảm bảo đã accept SSL certificate

### Code 9 (INVALID_TOKEN)
- Token sai hoặc không tồn tại
- Tạo lại device trong web dashboard
- Copy đúng token (không có space hay ký tự lạ)

### No Response
- Kiểm tra network connection
- Server có thể đang bận hoặc restart
- Thử disconnect và connect lại

### Pin Values không cập nhật
- Device chưa gửi data
- Kiểm tra ESP32 code có gọi `Blynk.virtualWrite()`
- Sync lại: gọi `syncWidget(pin)`
