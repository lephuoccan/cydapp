# CYDS Blynk Mobile App

A Flutter-based mobile application compatible with Blynk Legacy server, supporting Android, iOS, and Web platforms.

## Features

- 📱 Cross-platform support (Android, iOS, Web)
- 🔌 WebSocket connection to Blynk server
- 🎛️ Multiple widget types:
  - Button (Switch/Push mode)
  - Slider
  - Display (Value Display)
  - Gauge (Circular progress indicator)
  - LED Indicator
  - Terminal
- 💾 Local project storage
- 🎨 Material Design 3 UI
- 🌓 Light/Dark theme support

## Getting Started

### Prerequisites

- Flutter SDK (3.10.1 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Blynk Server running at C:\cydc\cyds\blynk-server

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run on your preferred platform:

**Web:**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

## Connecting to Blynk Server

1. Launch the app
2. Enter your Blynk server details:
   - Server Address: `localhost` (or your server IP)
   - Server Port: `8080` (default Blynk port)
   - Auth Token: Your project authentication token from Blynk server

3. Click **CONNECT** to establish connection

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── blynk_message.dart   # Blynk protocol message handling
│   ├── project.dart          # Project data model
│   └── widget_data.dart      # Widget data model
├── services/
│   ├── blynk_connection.dart # WebSocket connection to Blynk server
│   └── project_manager.dart  # Project and settings management
├── screens/
│   ├── login_screen.dart     # Connection screen
│   ├── projects_screen.dart  # Project list
│   └── dashboard_screen.dart # Widget dashboard
└── widgets/
    └── widget_renderer.dart  # Widget rendering components
```

## Supported Widgets

### Button
- Toggle switch or push button modes
- Virtual and digital pin support
- Customizable colors

### Slider
- Vertical slider control
- Configurable min/max values
- Real-time value updates

### Display
- Shows values from hardware/virtual pins
- Auto-updates when receiving data
- Customizable appearance

### Gauge
- Circular progress indicator
- Shows percentage-based values
- Visual value representation

### LED
- Visual indicator with glow effect
- ON/OFF states
- Color customization

### Terminal
- Monospace text display
- Scrollable content
- Terminal-style appearance

## Hardware Communication

The app supports standard Blynk protocol commands:

- **Virtual Pins**: `V0` - `V255`
- **Digital Pins**: `D0` - `D13`
- **Analog Pins**: `A0` - `A5`

### Commands
- `virtualWrite(pin, value)` - Write to virtual pin
- `digitalWrite(pin, value)` - Write to digital pin (0/1)
- `analogWrite(pin, value)` - Write PWM value (0-255)
- `syncWidget(pin)` - Request current value from hardware

## Configuration

Server settings are saved locally using SharedPreferences and persist between app sessions.

## Creating Projects

1. From Projects screen, tap the **+** button
2. Enter a project name
3. Or create a sample project with pre-configured widgets

## Development

### Adding New Widget Types

1. Add widget type to `WidgetType` enum in `widget_data.dart`
2. Create widget renderer class in `widget_renderer.dart`
3. Add case to `WidgetRenderer.build()` switch statement

### Modifying Blynk Protocol

Edit `BlynkMessage` and `BlynkCommand` classes in `blynk_message.dart` to add new protocol features.

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Troubleshooting

**Connection Failed:**
- Verify Blynk server is running
- Check server address and port
- Ensure auth token is correct
- Check firewall settings

**Widgets Not Updating:**
- Verify connection status (top-right indicator)
- Check pin configuration matches hardware
- Ensure hardware is sending data

## License

This project is created for CYDS and compatible with Blynk Legacy server protocol.

## Credits

Built with Flutter and inspired by Blynk Legacy mobile application.

