# Troubleshooting Connection Issues

## Vấn đề: WebSocketException: Failed to connect

### Nguyên nhân

1. **SSL Certificate chưa được accept** (Web apps trên Chrome)
2. **WebSocket path sai** (Hardware vs Dashboard)
3. **Server không chạy** hoặc firewall block

### Giải pháp

#### Bước 1: Accept SSL Certificate (BẮT BUỘC cho web app)

Trước khi connect trong app, **PHẢI** mở tab mới và accept certificate:

```
https://192.168.1.9:9443
```

Khi Chrome báo "Your connection is not private":
1. Click **Advanced**
2. Click **Proceed to 192.168.1.9 (unsafe)**
3. Đóng tab này lại
4. Quay về app và connect

**LƯU Ý**: Phải làm mỗi khi restart Chrome!

#### Bước 2: Chọn đúng WebSocket Path

Server Blynk có 2 WebSocket paths khác nhau:

| Path | Mục đích | Client | Login Command |
|------|----------|--------|---------------|
| `/websocket` | Hardware connection | ESP32, Arduino | Command 2 (LOGIN) |
| `/dashws` | Web dashboard | Browser app, Mobile app | Command 29 (APP_LOGIN) |

**Để connect như ESP32/hardware device**: Chọn `/websocket`

**Để connect như user dashboard**: Chọn `/dashws` (nhưng cần dùng APP_LOGIN command 29, không phải LOGIN command 2)

#### Bước 3: Test Connection

Sau khi accept certificate:

1. Mở Device Test Screen
2. Nhập:
   - Server IP: `192.168.1.9`
   - Port: `9443`
   - Auth Token: `jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe`
   - **Path: `/websocket`** (cho hardware)
3. Click **CONNECT**

Kiểm tra terminal output:
```
🔌 Connecting to wss://192.168.1.9:9443/websocket
📡 WebSocket connecting...
🔐 Sending hardware login with token: jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe
📥 Received 7 bytes
📨 Command: 0, MessageId: 1
Response code: 200 ✅ OK
✅ Connection established!
```

Nếu thấy `Response code: 200 ✅ OK` → **Thành công!**

### Test với ESP32 Code

Nếu ESP32 của bạn đang chạy và gửi data lên V0, app sẽ nhận được:

```
📥 Received X bytes
📨 Command: 20, MessageId: Y
🔧 Hardware: [vw, 0, value]
📍 Pin V0 = value
```

Và hiển thị trong "Pin Values":
```
V0: value
```

### Các Response Codes thường gặp

| Code | Tên | Nghĩa | Giải pháp |
|------|-----|-------|-----------|
| 200 | OK | Thành công | ✅ Đã kết nối |
| 9 | INVALID_TOKEN | Token sai hoặc không tồn tại | Kiểm tra lại token, tạo device mới |
| 2 | ILLEGAL_COMMAND | Command không hợp lệ | Path sai - thử đổi sang `/websocket` |
| 4 | INVALID_TOKEN | Token không đúng định dạng | Copy lại token từ dashboard |

### Port Configuration

| Port | Protocol | Mục đích | SSL |
|------|----------|----------|-----|
| 8080 | TCP/WebSocket | Hardware (không SSL) | ❌ No |
| 9443 | WebSocket Secure | App + Hardware (SSL) | ✅ Yes |

Web app **PHẢI** dùng port 9443 (wss://) vì browser yêu cầu secure connection.

### Debug Steps

1. **Mở Chrome DevTools** (F12)
2. Tab **Console** - xem Flutter debug logs
3. Tab **Network** → Filter: WS (WebSocket)
4. Click vào websocket connection → Tab **Messages**
5. Xem messages được gửi/nhận

### So sánh với ESP32 hoạt động

Nếu ESP32 với app Blynk cũ vẫn hoạt động:

- ESP32 có thể đang dùng **TCP port 8080** (không phải WebSocket)
- ESP32 có thể đang dùng **WebSocket path `/websocket`**
- ESP32 không cần accept SSL certificate (dùng hardware library tự động)

Web app của chúng ta:
- **BẮT BUỘC** dùng WebSocket Secure (wss://)
- **BẮT BUỘC** accept certificate trong browser
- Cần chọn đúng path (`/websocket` cho hardware emulation)

### Test với curl (từ terminal)

Để test server mà không cần browser:

```bash
# Test SSL certificate
curl -k https://192.168.1.9:9443

# Test WebSocket path exists (sẽ fail vì không phải WebSocket client)
curl -k https://192.168.1.9:9443/websocket
curl -k https://192.168.1.9:9443/dashws
```

### Giải pháp cuối cùng

Nếu vẫn không connect được:

1. ✅ Accept certificate: `https://192.168.1.9:9443`
2. ✅ Chọn path: `/websocket`
3. ✅ Nhập đúng token: `jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe`
4. ✅ Port: `9443`
5. ✅ Kiểm tra server đang chạy
6. ✅ Check terminal logs để xem response code

Nếu response code = 200 nhưng không nhận pin values:
- ESP32 chưa gửi data
- Hoặc ESP32 đang gửi đến device khác (kiểm tra token)
