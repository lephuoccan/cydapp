# CYDS Blynk - Quick Start Guide

## 🚀 Khởi Chạy Nhanh

### 1. Cài Đặt Dependencies
```bash
cd C:\cydc\cyds\mobileapp\cyds
flutter pub get
```

### 2. Chạy Ứng Dụng

#### Chạy trên Chrome (Web) - Khuyến nghị cho test
```bash
flutter run -d chrome
```

#### Chạy trên Windows Desktop
```bash
flutter run -d windows
```

#### Chạy trên Android
```bash
flutter run -d android
```

### 3. Kết Nối Server Blynk

Sau khi ứng dụng khởi động:

1. **Server Address**: `localhost` hoặc `127.0.0.1`
2. **Server Port**: `8080`
3. **Auth Token**: Lấy từ Blynk server tại `C:\cydc\cyds\blynk-server`

### 4. Tạo Dự Án Mẫu

- Nhấn biểu tượng **+** ở góc trên
- Hoặc nhấn "Create Sample Project" nếu chưa có dự án
- Dự án mẫu bao gồm:
  - ✅ Button (LED Control) - Virtual Pin V1
  - ✅ Slider (Brightness) - Virtual Pin V2
  - ✅ Display (Temperature) - Virtual Pin V3
  - ✅ Gauge (Humidity) - Virtual Pin V4

## 📱 Hỗ Trợ Nền Tảng

- ✅ **Web** (Chrome, Edge, Firefox)
- ✅ **Android** (5.0+)
- ✅ **iOS** (11.0+)
- ✅ **Windows Desktop**
- ✅ **macOS**
- ✅ **Linux**

## 🎯 Kiểm Tra Kết Nối

### Trạng thái kết nối hiển thị ở góc trên bên phải:
- 🟢 **Online** - Đã kết nối với server
- 🔴 **Offline** - Chưa kết nối

## 🔧 Cấu Hình Blynk Server

Đảm bảo Blynk server đang chạy:

```bash
cd C:\cydc\cyds\blynk-server
# Chạy server theo hướng dẫn của Blynk
```

## 📊 Widget Có Sẵn

| Widget | Mô Tả | Pin Type |
|--------|-------|----------|
| Button | Nút bấm ON/OFF | Virtual, Digital |
| Slider | Thanh trượt giá trị | Virtual, Analog |
| Display | Hiển thị giá trị | Virtual, Digital, Analog |
| Gauge | Đồng hồ đo tròn | Virtual, Analog |
| LED | Đèn LED | Virtual, Digital |
| Terminal | Hiển thị text | Virtual |

## 🐛 Debug

Xem log trong terminal hoặc Debug Console:
- WebSocket connection status
- Message send/receive
- Widget value updates

## 💡 Tips

1. **Offline Mode**: Có thể duyệt projects khi offline
2. **Auto-save**: Tất cả thay đổi được lưu tự động
3. **Multi-project**: Quản lý nhiều dự án cùng lúc
4. **Real-time**: Widget cập nhật real-time khi có dữ liệu

## 📦 Build Release

### Web
```bash
flutter build web --release
cd build\web
python -m http.server 8000
```

### Android APK
```bash
flutter build apk --release
```

### Windows
```bash
flutter build windows --release
```

## 🎨 Customization

Màu chủ đạo có thể đổi trong `lib/main.dart`:
- Default: Blue (#2196F3)
- Hỗ trợ Material Design 3 colors

## 📞 Support

Gặp vấn đề? Kiểm tra:
1. Flutter doctor: `flutter doctor -v`
2. Dependencies: `flutter pub get`
3. Clean build: `flutter clean`
