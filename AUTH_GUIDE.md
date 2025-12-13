# Phân Biệt Client Types và Authentication

## 🎯 TÓM TẮT QUAN TRỌNG

### Web/Mobile App (Dashboard) - DÙNG EMAIL/PASSWORD
```bash
flutter run -d chrome -t lib/main.dart
# hoặc
flutter run -d chrome -t lib/main_test.dart
```

- **Login**: Email + Password (lephuoccan@gmail.com / 111111)
- **Path**: `/dashws` (Web Dashboard)
- **Command**: `29` (APP_LOGIN)
- **Port**: `9443` (WebSocket Secure)
- **Mục đích**: Quản lý projects, xem/điều khiển devices

### ESP32/Hardware - DÙNG AUTH TOKEN
```bash
flutter run -d chrome -t lib/main_device_test.dart
```

- **Login**: Auth Token (jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe)
- **Path**: `/websocket` (Hardware)
- **Command**: `2` (LOGIN)
- **Port**: `9443` hoặc `8080`
- **Mục đích**: Test/emulate ESP32, nhận hardware commands

---

## 📋 Chi Tiết Authentication Flow

### 1. Web/Mobile App Authentication

**File**: `lib/services/auth_service.dart`

**Protocol**:
```
WebSocket: wss://192.168.1.9:9443/dashws

Message Format (3-byte header):
[29 | messageId(2 bytes) | body]

Body (5 parts, separated by \0):
email | passwordHash | "web" | "1.0.0" | "Blynk"

Password Hash:
Base64(SHA256(password + SHA256(email.toLowerCase())))

Response:
[0 | messageId(2) | code(4 bytes int32)]
Code 200 = Success
```

**Example**:
```dart
// Email: lephuoccan@gmail.com
// Password: 111111
// Hash: 9H6DuiAU++3Q8ScGEhoJgylXlXDOT999sVl6mWqaD6Q=

Body: "lephuoccan@gmail.com\09H6DuiAU++3Q8ScGEhoJgylXlXDOT999sVl6mWqaD6Q=\0web\01.0.0\0Blynk"
```

**Kết quả**: Nhận user info, projects, devices từ server

---

### 2. Hardware Device Authentication

**File**: `lib/services/blynk_connection.dart`

**Protocol**:
```
WebSocket: wss://192.168.1.9:9443/websocket

Message Format (3-byte header):
[2 | messageId(2 bytes) | authToken]

Auth Token:
Lấy từ web dashboard khi tạo device
VD: jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe

Response:
[0 | messageId(2) | code(4 bytes int32)]
Code 200 = Success
```

**Example**:
```dart
// Command 2 = LOGIN
// Token: jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe

Body: "jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe"
```

**Kết quả**: Nhận hardware commands, gửi pin values

---

## 🔄 Data Flow After Authentication

### Web/Mobile App (User)
```
1. Login với email/password → Code 200
2. Load projects → Command GET_PROJECTS
3. Load devices → Command GET_DEVICES
4. Xem dashboard → Subscribe to pin updates
5. Điều khiển device → Send HARDWARE commands
```

### Hardware (ESP32)
```
1. Login với token → Code 200
2. Gửi data → Command 20 (HARDWARE): vw\0pin\0value
3. Nhận commands → Parse HARDWARE messages
4. Ping/Keep-alive → Command 6 every 10s
```

---

## 🛠️ Cách Sử Dụng Đúng

### Scenario 1: Tôi muốn dùng app như user (xem dashboard, điều khiển devices)

✅ **Dùng main.dart hoặc main_test.dart**

```bash
# Bước 1: Accept SSL certificate
# Mở tab: https://192.168.1.9:9443
# Advanced → Proceed

# Bước 2: Chạy app
flutter run -d chrome -t lib/main_test.dart

# Bước 3: Click CONNECT
# App sẽ login với:
# - Email: lephuoccan@gmail.com
# - Password: 111111
# - Path: /dashws
# - Command: 29 (APP_LOGIN)
```

**Kết quả**: Login thành công, thấy "Connected successfully! ✓"

---

### Scenario 2: Tôi muốn test kết nối như ESP32 (emulate hardware)

✅ **Dùng main_device_test.dart**

```bash
# Bước 1: Lấy auth token từ web dashboard
# Tạo device → Copy token

# Bước 2: Accept SSL certificate
# Mở tab: https://192.168.1.9:9443

# Bước 3: Chạy device test
flutter run -d chrome -t lib/main_device_test.dart

# Bước 4: Nhập thông tin
# - Server IP: 192.168.1.9
# - Port: 9443
# - Token: jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe
# - Path: /websocket

# Bước 5: Click CONNECT
```

**Kết quả**: Kết nối như ESP32, nhận hardware commands, xem pin values

---

## 📊 So Sánh

| Feature | Web/Mobile App | Hardware (ESP32) |
|---------|----------------|------------------|
| **Entry Point** | `main.dart` / `main_test.dart` | `main_device_test.dart` |
| **Auth Method** | Email + Password | Auth Token |
| **WebSocket Path** | `/dashws` | `/websocket` |
| **Login Command** | `29` (APP_LOGIN) | `2` (LOGIN) |
| **Service** | `auth_service.dart` | `blynk_connection.dart` |
| **Data Format** | 5-part body | Simple token |
| **Purpose** | Dashboard, control | Receive/send hardware data |
| **User Type** | Human user | IoT device |

---

## ⚠️ LƯU Ý QUAN TRỌNG

### SSL Certificate (Cả 2 loại đều cần)
Trước khi chạy bất kỳ app nào trên web, **BẮT BUỘC** accept certificate:
```
https://192.168.1.9:9443
Advanced → Proceed to 192.168.1.9 (unsafe)
```

### Port Usage
- **9443**: WebSocket Secure (wss://) - BẮT BUỘC cho web app
- **8080**: TCP hoặc WebSocket không SSL - Chỉ cho hardware/server-to-server

### Token vs Password
- **Token**: Cho device/hardware, không có thông tin user
- **Password**: Cho user login, có quyền quản lý toàn bộ account

### Path Selection
- **/dashws**: Dashboard, app login, quản lý
- **/websocket**: Hardware, device communication

---

## 🐛 Troubleshooting

### "Connection Failed" khi dùng email/password
✅ Kiểm tra đang chạy `main_test.dart` hoặc `main.dart` (KHÔNG phải `main_device_test.dart`)
✅ Đã accept SSL certificate
✅ Server đang chạy
✅ Email/password đúng

### "Code 9 INVALID_TOKEN" khi dùng device test
✅ Token đúng (copy từ web dashboard)
✅ Path là `/websocket` (không phải `/dashws`)
✅ Device đã được tạo trong project

### ESP32 hoạt động nhưng app không nhận data
❌ Đang chạy `main_device_test.dart` (device emulation)
✅ Phải chạy `main.dart` hoặc `main_test.dart` (user app)
✅ Login bằng email/password, không phải token

---

## 📖 Tham Khảo

Server source code: https://github.com/lephuoccan/iotserver

Key files:
- `MobileLoginHandler.java` - APP_LOGIN (email/password)
- `LoginHandler.java` - LOGIN (token)
- `WebSocketHandler.java` - WebSocket paths
- `SHA256Util.java` - Password hashing

---

## ✅ Quick Start Guide

### Cho User App (Recommended):
```bash
flutter run -d chrome -t lib/main_test.dart
```
→ Click CONNECT → Login với email/password → Xem dashboard

### Cho Hardware Test (Advanced):
```bash
flutter run -d chrome -t lib/main_device_test.dart
```
→ Nhập token → Select /websocket → CONNECT → Test như ESP32
