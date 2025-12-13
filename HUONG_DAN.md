# Hướng Dẫn Sử Dụng CYDS Blynk

## Giới Thiệu

Ứng dụng CYDS Blynk là ứng dụng di động tương thích với Blynk Legacy server, hỗ trợ Android, iOS và Web.

## Tính Năng Chính

- 📱 Hỗ trợ đa nền tảng (Android, iOS, Web)
- 🔌 Kết nối WebSocket đến Blynk server
- 🎛️ Nhiều loại widget:
  - Nút bấm (Button)
  - Thanh trượt (Slider)
  - Hiển thị giá trị (Display)
  - Đồng hồ đo (Gauge)
  - Đèn LED
  - Terminal
- 💾 Lưu trữ dự án cục bộ
- 🎨 Giao diện Material Design 3
- 🌓 Hỗ trợ chế độ sáng/tối

## Cài Đặt

### Yêu Cầu

- Flutter SDK (phiên bản 3.10.1 trở lên)
- Blynk Server đang chạy tại C:\cydc\cyds\blynk-server

### Các Bước Cài Đặt

1. Cài đặt các thư viện phụ thuộc:
```bash
cd C:\cydc\cyds\mobileapp\cyds
flutter pub get
```

2. Chạy ứng dụng:

**Trên Web:**
```bash
flutter run -d chrome
```

**Trên Android:**
```bash
flutter run -d android
```

**Trên iOS:**
```bash
flutter run -d ios
```

## Hướng Dẫn Sử Dụng

### 1. Kết Nối Đến Server

1. Mở ứng dụng
2. Nhập thông tin server:
   - **Địa chỉ Server**: `localhost` (hoặc địa chỉ IP của server)
   - **Cổng Server**: `8080` (cổng mặc định của Blynk)
   - **Auth Token**: Mã xác thực của dự án từ Blynk server
3. Nhấn nút **CONNECT** để kết nối

### 2. Quản Lý Dự Án

#### Tạo Dự Án Mẫu
- Nhấn biểu tượng **+** ở góc trên bên phải
- Dự án mẫu sẽ có sẵn các widget cơ bản

#### Tạo Dự Án Mới
- Nhấn nút **+** ở góc dưới bên phải
- Nhập tên dự án
- Nhấn **CREATE**

#### Xóa Dự Án
- Nhấn vào biểu tượng 3 chấm trên thẻ dự án
- Chọn **Delete**
- Xác nhận xóa

### 3. Sử Dụng Dashboard

#### Các Loại Widget

**Nút Bấm (Button)**
- Nhấn để bật/tắt
- Gửi giá trị 0 hoặc 1 đến chân ảo/số
- Màu sắc thay đổi theo trạng thái

**Thanh Trượt (Slider)**
- Kéo thanh trượt để thay đổi giá trị
- Tự động gửi giá trị đến server
- Hiển thị giá trị hiện tại

**Hiển Thị (Display)**
- Hiển thị giá trị từ hardware
- Tự động cập nhật khi nhận dữ liệu mới
- Chỉ đọc

**Đồng Hồ Đo (Gauge)**
- Hiển thị giá trị dạng vòng tròn
- Có giá trị min/max
- Trực quan và dễ nhìn

**Đèn LED**
- Hiển thị trạng thái ON/OFF
- Có hiệu ứng phát sáng khi bật
- Màu sắc tùy chỉnh

**Terminal**
- Hiển thị văn bản dạng terminal
- Có thể cuộn nội dung
- Phông chữ monospace

## Cấu Trúc Chân (Pin)

### Loại Chân
- **Virtual Pins**: `V0` - `V255` (chân ảo)
- **Digital Pins**: `D0` - `D13` (chân số)
- **Analog Pins**: `A0` - `A5` (chân tương tự)

### Các Lệnh
- `virtualWrite(pin, value)` - Ghi giá trị vào chân ảo
- `digitalWrite(pin, value)` - Ghi giá trị số (0/1)
- `analogWrite(pin, value)` - Ghi giá trị PWM (0-255)

## Xây Dựng Ứng Dụng

### Android (APK)
```bash
flutter build apk --release
```
File APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```
File web sẽ được tạo tại: `build/web/`

## Khắc Phục Sự Cố

### Không Kết Nối Được
- Kiểm tra Blynk server đang chạy
- Xác nhận địa chỉ và cổng server
- Kiểm tra auth token
- Kiểm tra tường lửa (firewall)

### Widget Không Cập Nhật
- Kiểm tra trạng thái kết nối (góc trên bên phải)
- Xác nhận cấu hình chân khớp với hardware
- Đảm bảo hardware đang gửi dữ liệu

### Lỗi Cài Đặt Dependencies
```bash
flutter clean
flutter pub get
```

## Tùy Chỉnh

### Thay Đổi Màu Chủ Đạo
Sửa file `lib/main.dart`:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.blue,  // Đổi màu tại đây
),
```

### Thêm Widget Mới
1. Thêm loại widget vào `WidgetType` trong `lib/models/widget_data.dart`
2. Tạo class renderer trong `lib/widgets/widget_renderer.dart`
3. Thêm case vào hàm `build()` của `WidgetRenderer`

## Liên Hệ Hỗ Trợ

Nếu gặp vấn đề, vui lòng kiểm tra:
1. Phiên bản Flutter: `flutter --version`
2. Các dependency: `flutter doctor`
3. Log lỗi: Xem trong VS Code Debug Console

## Ghi Chú

- Ứng dụng lưu cài đặt tự động
- Dự án được lưu cục bộ trên thiết bị
- Kết nối WebSocket tự động ping mỗi 10 giây
- Hỗ trợ cả IPv4 và tên miền

## Tính Năng Sắp Tới

- [ ] Thêm widget Graph (Biểu đồ)
- [ ] Hỗ trợ Joystick
- [ ] RGB Color Picker
- [ ] Timer widget
- [ ] Notification push
- [ ] Chia sẻ dự án
- [ ] Export/Import cấu hình

## Bản Quyền

Dự án CYDS - Tương thích với Blynk Legacy server protocol
