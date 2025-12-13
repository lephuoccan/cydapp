# Dashboard Feature - Hướng dẫn sử dụng

## Tổng quan
Dashboard cho phép hiển thị và điều khiển ESP32 qua nhiều tabs với các widgets khác nhau.

## Cấu trúc

### Models
- **DataStream** (`lib/models/data_stream.dart`): Quản lý pin configuration
  - `pin`: Số pin (0-255 cho Virtual, 0-13 cho Digital, 0-7 cho Analog)
  - `pinType`: Loại pin (VIRTUAL, DIGITAL, ANALOG)
  - `value`: Giá trị hiện tại
  - `min`, `max`: Giới hạn cho slider
  - `pinKey`: Tự động tạo key (V0, D1, A2...)

- **WidgetModel** (`lib/models/widget_model.dart`): Widget trên dashboard
  - `id`: ID duy nhất
  - `x`, `y`: Vị trí trong grid
  - `width`, `height`: Kích thước
  - `type`: Loại widget (VALUE_DISPLAY, BUTTON, SLIDER, LED...)
  - `label`: Nhãn hiển thị
  - `dataStream`: Pin binding
  - `tabId`: Thuộc tab nào
  - `deviceId`: Thuộc device nào

- **TabModel** (`lib/models/tab.dart`): Tab trong dashboard
  - `id`: ID tab
  - `label`: Tên tab
  - `selectedDeviceId`: Device được chọn cho tab này

- **Dashboard** (`lib/models/dashboard.dart`): Dashboard chính
  - `id`, `name`: ID và tên dashboard
  - `widgets`: Danh sách widgets
  - `tabs`: Danh sách tabs
  - `deviceIds`: Danh sách device IDs có thể chọn
  - `isActive`: Dashboard có đang active không

### UI Components

#### BlynkDashboardScreen (`lib/screens/blynk_dashboard_screen.dart`)
- TabController để quản lý tabs
- Device selector dropdown (chọn device cho mỗi tab)
- GridView hiển thị widgets
- Tự động update khi pin value thay đổi từ ESP32

#### BlynkWidgetRenderer (`lib/widgets/blynk_widget_renderer.dart`)
Hỗ trợ 4 loại widget:

1. **VALUE_DISPLAY**: Hiển thị giá trị từ ESP32
   - Gradient xanh dương
   - Hiển thị label, value, pin key
   - Tự động update real-time

2. **BUTTON**: Nút bấm điều khiển
   - Gradient xanh lá
   - onTap: Gửi giá trị 1
   - onTapUp: Gửi giá trị 0 (sau 100ms)
   - Icon touch_app

3. **SLIDER**: Thanh trượt điều chỉnh
   - Gradient tím
   - Min/max từ dataStream
   - onChange: Gửi giá trị mới về ESP32
   - Hiển thị giá trị hiện tại

4. **LED**: Đèn LED hiển thị trạng thái
   - Gradient cam (ON) hoặc xám (OFF)
   - Icon lightbulb khi ON, lightbulb_outline khi OFF
   - Đọc từ pin value (1/true = ON, 0/false = OFF)

### Factory

**DashboardFactory** (`lib/utils/dashboard_factory.dart`)
- `createDemoDashboard()`: Tạo dashboard demo với:
  - **Tab 1 - Cảm biến**: VALUE_DISPLAY (V0, V1), LED (V2)
  - **Tab 2 - Điều khiển**: BUTTON (V3, V5), SLIDER (V4, V6)

## Cách sử dụng

### 1. Kết nối BlynkService
```dart
final blynkService = BlynkServiceSimple();
await blynkService.connect(ip, port, email, password);
```

### 2. Tạo Dashboard
```dart
final dashboard = DashboardFactory.createDemoDashboard();
// Hoặc tạo custom:
final dashboard = Dashboard(
  id: 1,
  name: 'My Dashboard',
  widgets: [...],
  tabs: [...],
  deviceIds: [1, 2, 3],
);
```

### 3. Hiển thị Dashboard
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlynkDashboardScreen(
      dashboard: dashboard,
      blynkService: blynkService,
    ),
  ),
);
```

### 4. Mở Dashboard từ HomeScreen
- Sau khi connect thành công
- Nhấn icon dashboard ở AppBar
- Tự động mở demo dashboard

## Luồng dữ liệu

### ESP32 → App (Nhận data)
1. ESP32 gửi Command 20 với body: `vw\x00{pin}\x00{value}`
2. BlynkService parse và lưu vào `pinValues` Map
3. BlynkService.notifyListeners()
4. Dashboard._onPinValueChanged() được gọi
5. Dashboard update widgets có matching pin
6. Widget renderer hiển thị giá trị mới

### App → ESP32 (Gửi data)
1. User tương tác với widget (button click, slider change)
2. Widget gọi `blynkService.sendVirtualPin(pin, value)`
3. BlynkService gửi Command 20: `vw\x00{pin}\x00{value}`
4. ESP32 nhận và xử lý

## Pin Mapping Demo

| Widget | Type | Pin | Mô tả |
|--------|------|-----|-------|
| Nhiệt độ | VALUE_DISPLAY | V0 | Hiển thị nhiệt độ từ cảm biến |
| Độ ẩm | VALUE_DISPLAY | V1 | Hiển thị độ ẩm từ cảm biến |
| Trạng thái | LED | V2 | LED hiển thị trạng thái hệ thống |
| Bật/Tắt LED | BUTTON | V3 | Điều khiển LED on/off |
| Tốc độ quạt | SLIDER | V4 | Điều chỉnh tốc độ quạt (0-255) |
| Máy bơm | BUTTON | V5 | Bật/tắt máy bơm |
| Độ sáng | SLIDER | V6 | Điều chỉnh độ sáng (0-100) |

## Tùy chỉnh

### Thêm widget type mới
1. Thêm case vào `BlynkWidgetRenderer.build()`
2. Tạo method `_buildYourWidget()`
3. Thiết kế UI và logic tương tác

### Thêm tab mới
```dart
final newTab = TabModel(id: 3, label: 'Tab mới');
```

### Thêm widget vào tab
```dart
final widget = WidgetModel(
  id: 10,
  type: 'VALUE_DISPLAY',
  label: 'Widget mới',
  tabId: 3, // Thuộc tab 3
  dataStream: DataStream(pin: 10, pinType: 'VIRTUAL'),
);
```

## Debug

### Kiểm tra pin values
```dart
print(blynkService.pinValues); // Map<String, String>
```

### Kiểm tra widget update
```dart
// Trong BlynkDashboardScreen._onPinValueChanged()
debugPrint('Pin $pinKey updated to: $value');
```

### Test ESP32 code
```cpp
// Gửi data về app
Blynk.virtualWrite(V0, temperature);
Blynk.virtualWrite(V1, humidity);

// Nhận data từ app
BLYNK_WRITE(V3) {
  int value = param.asInt();
  digitalWrite(LED_PIN, value);
}
```

## Tính năng tiếp theo
- [ ] Thêm widget types: GRAPH, LCD, TABLE
- [ ] Lưu dashboard configuration vào server
- [ ] Tải dashboard từ JSON
- [ ] Edit mode để thêm/sửa/xóa widgets
- [ ] Multi-device support (chọn device cho từng tab)
- [ ] Widget resizing và repositioning
