# Server Profile Integration - Dashboard từ Server

## Tổng quan
App tự động load dashboard configuration từ server sau khi login thành công, thay vì dùng hardcoded demo dashboard.

## Luồng hoạt động

### 1. Login thành công
```
User -> AuthService.login() 
     -> Server responds code 200
     -> Server gửi LOAD_PROFILE_GZIPPED (command 24)
```

### 2. Nhận Profile từ Server
```
Server -> Command 24 (LOAD_PROFILE_GZIPPED)
       -> GZIP compressed JSON
       -> BlynkService decompresses
       -> Lưu vào profileJson
```

### 3. Parse Profile thành Dashboard
```
profileJson -> ProfileParser.parseProfile()
            -> Dashboard model (widgets, tabs, devices)
            -> Hiển thị trên UI
```

## Server Profile Format

Profile JSON từ server có cấu trúc:
```json
{
  "dashBoards": [
    {
      "id": 1683803793,
      "name": "testesp32",
      "isActive": true,
      "widgets": [
        {
          "type": "DIGIT4_DISPLAY",
          "id": 94027,
          "x": 0,
          "y": 0,
          "width": 2,
          "height": 1,
          "tabId": 0,
          "deviceId": 0,
          "pin": -1
        },
        {
          "type": "GAUGE",
          "id": 114552,
          "x": 2,
          "y": 0,
          "width": 4,
          "height": 3,
          "tabId": 0,
          "deviceId": 0,
          "pinType": "VIRTUAL",
          "pin": 0,
          "min": 0.0,
          "max": 1023.0,
          "value": "3328022"
        },
        {
          "type": "TERMINAL",
          "id": 105960,
          "x": 0,
          "y": 3,
          "width": 8,
          "height": 3,
          "tabId": 0,
          "deviceId": 0,
          "pinType": "VIRTUAL",
          "pin": 1,
          "autoScrollOn": true,
          "terminalInputOn": true
        },
        {
          "type": "STYLED_BUTTON",
          "id": 32728,
          "x": 0,
          "y": 6,
          "width": 4,
          "height": 1,
          "tabId": 0,
          "deviceId": 0,
          "pinType": "VIRTUAL",
          "pin": 1,
          "value": "0",
          "pushMode": false
        }
      ],
      "devices": [
        {
          "id": 0,
          "name": "testesp32",
          "boardType": "ESP32 Dev Board",
          "token": "jzjFAo3nkDoW_aIDwN7OhpbHw7sCQfJe",
          "status": "ONLINE",
          "lastLoggedIP": "192.168.1.12"
        }
      ]
    }
  ]
}
```

## ProfileParser Service

### `lib/services/profile_parser.dart`

#### parseProfile(String profileJson)
- Input: GZIP decompressed JSON string từ server
- Output: Dashboard model hoặc null nếu parse fail
- Logic:
  1. Parse JSON
  2. Tìm dashboard với isActive=true (hoặc dashboard đầu tiên)
  3. Parse widgets array
  4. Parse devices array
  5. Tạo tabs từ tabId của widgets
  6. Return Dashboard model

#### _parseDashboard(Map data)
- Parse dashboard properties: id, name, isActive
- Parse devices -> deviceIds list
- Parse widgets -> WidgetModel list
- Tạo tabs từ unique tabIds
- Return Dashboard

#### _parseWidget(Map data)
- Parse widget properties: type, id, x, y, width, height, label, color
- Parse dataStream (pin, pinType, min, max, value)
- Map Blynk widget type sang app widget type
- Return WidgetModel

#### _mapWidgetType(String blynkType)
Map Blynk server widget types sang app widget types:

| Blynk Type | App Type | Mô tả |
|------------|----------|-------|
| DIGIT4_DISPLAY | VALUE_DISPLAY | Hiển thị số 4 chữ số |
| VALUE_DISPLAY | VALUE_DISPLAY | Hiển thị giá trị |
| LABELED_VALUE_DISPLAY | VALUE_DISPLAY | Hiển thị với label |
| GAUGE | GAUGE | Đồng hồ đo |
| LEVEL_H | GAUGE | Thanh ngang |
| LEVEL_V | GAUGE | Thanh dọc |
| BUTTON | BUTTON | Nút bấm thường |
| STYLED_BUTTON | BUTTON | Nút bấm có style |
| SLIDER | SLIDER | Thanh trượt ngang |
| VERTICAL_SLIDER | SLIDER | Thanh trượt dọc |
| LED | LED | LED hiển thị trạng thái |
| TERMINAL | TERMINAL | Console text |
| LCD | TERMINAL | LCD display |
| TEXT_INPUT | TERMINAL | Nhập text |
| GRAPH | GRAPH | Biểu đồ (chưa implement) |
| ENHANCED_GRAPH | GRAPH | Biểu đồ nâng cao |
| SUPERCHART | GRAPH | Super chart |

## BlynkService Updates

### Thêm properties:
```dart
String? _profileJson; // Store profile JSON
String? get profileJson => _profileJson;
```

### Thêm handler cho command 24:
```dart
else if (command == BlynkCommand.loadProfileGzipped) {
  final compressedData = bytes.sublist(3);
  final decompressed = gzip.decode(compressedData);
  final profileJson = utf8.decode(decompressed);
  
  _profileJson = profileJson;
  notifyListeners();
}
```

### Import thêm:
```dart
import 'dart:io'; // For gzip
```

## HomeScreen Updates

### Dashboard button:
```dart
onPressed: () {
  // Load from server profile first
  var dashboard = blynkService.profileJson != null
      ? ProfileParser.parseProfile(blynkService.profileJson!)
      : null;
  
  // Fallback to demo if no profile
  dashboard ??= DashboardFactory.createDemoDashboard();
  
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => BlynkDashboardScreen(
      dashboard: dashboard!,
      blynkService: blynkService,
    ),
  ));
}
```

## Widget Renderer Updates

### Thêm widget types:

#### GAUGE (Đồng hồ đo)
- Circular progress indicator
- Hiển thị phần trăm và giá trị thực
- Min/max từ dataStream
- Auto-calculate percentage: `(value - min) / (max - min) * 100`

#### TERMINAL (Console)
- Black background với text xanh (greenAccent)
- Monospace font
- Scrollable
- Hiển thị giá trị từ pin (text data)

## Test với database thực

Database user `lephuoccan@gmail.com`:
- Project: **testesp32** (id: 1683803793)
- Widgets: 4 widgets
  * DIGIT4_DISPLAY (id: 94027) - Tab 0, no pin
  * GAUGE (id: 114552) - Tab 0, V0, range 0-1023
  * TERMINAL (id: 105960) - Tab 0, V1
  * STYLED_BUTTON (id: 32728) - Tab 0, V1
- Device: ESP32 Dev Board (id: 0)
- Status: ONLINE

## Debug

### Kiểm tra profile đã nhận:
```dart
print('Profile: ${blynkService.profileJson}');
```

### Kiểm tra parse thành công:
```dart
final dashboard = ProfileParser.parseProfile(profileJson);
print('Dashboard: ${dashboard?.name}');
print('Widgets: ${dashboard?.widgets.length}');
print('Tabs: ${dashboard?.tabs.length}');
```

### Test flow:
1. Login thành công → Server gửi command 24
2. BlynkService decompresses GZIP → Lưu profileJson
3. Click dashboard button → Parse profile
4. Dashboard hiển thị widgets từ server config
5. Real-time data updates từ ESP32

## Lưu ý

### GZIP Decompression
- Server gửi profile đã nén GZIP
- Cần import `dart:io` để dùng `gzip.decode()`
- Web platform không support `dart:io` → Cần dùng package khác cho web (e.g., `archive` package)

### Pin Matching
- Widget pin phải khớp với ESP32 gửi data
- GAUGE widget có pin=0 → Nhận V0 từ ESP32
- TERMINAL widget có pin=1 → Nhận V1 từ ESP32

### Tab Grouping
- Widgets có cùng tabId được group vào 1 tab
- tabId=0 → "Main" tab
- tabId=1,2,3... → "Tab 1", "Tab 2", "Tab 3"...

### Device Selection
- Dashboard có nhiều devices
- Tab có thể chọn device nào
- Widget chỉ hiển thị data từ device được chọn

## Tính năng tiếp theo
- [ ] Hỗ trợ GZIP cho web platform (dùng `archive` package)
- [ ] Cache profile locally để offline access
- [ ] Refresh profile button
- [ ] Multi-dashboard support
- [ ] Widget configuration editor
- [ ] GRAPH widget implementation
- [ ] LCD widget với multi-line display
