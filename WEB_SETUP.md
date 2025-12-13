# Setup cho Web (Chrome)

## Vấn đề với Self-Signed SSL Certificate

Khi chạy app trên web browser (Chrome), WebSocket không thể kết nối đến server với self-signed certificate tự động.

## Giải pháp:

### Bước 1: Accept Certificate trong Chrome

1. Mở tab mới trong Chrome
2. Truy cập: **https://192.168.1.9:9443**
3. Chrome sẽ hiện cảnh báo "Your connection is not private"
4. Click **"Advanced"**
5. Click **"Proceed to 192.168.1.9 (unsafe)"**
6. Bạn sẽ thấy trang web của Blynk server (hoặc lỗi 404 - không sao)

### Bước 2: Chạy App

Sau khi accept certificate, quay lại app và click **"Test Connection"**

App sẽ kết nối thành công với code **200 = OK**

## Test với Dart Script (không cần accept certificate)

```bash
dart test_ws_format.dart
```

Script này dùng `dart:io` WebSocket nên có thể accept certificate tự động.

## Kết quả khi thành công:

```
📤 Sending LOGIN to /dashws
📥 Received 7 bytes
   Response code: 200
   Status: OK
🎉 SUCCESS! Logged in to /dashws!
```

## Nếu vẫn lỗi:

1. Kiểm tra Blynk server có đang chạy: `C:\cydc\cyds\blynk-server`
2. Check firewall không block port 9443
3. Verify server IP: 192.168.1.9
