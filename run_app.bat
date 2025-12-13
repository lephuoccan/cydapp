@echo off
echo ========================================
echo   CYDS - Blynk Client App
echo ========================================
echo.
echo Chon loai app muon chay:
echo.
echo 1. User App (Email/Password) - Recommended
echo    - Login: lephuoccan@gmail.com / 111111
echo    - Xem data tu ESP32 real-time
echo.
echo 2. Device Test (Auth Token)
echo    - Emulate ESP32/hardware
echo    - Test device connection
echo.
set /p choice="Chon (1 hoac 2): "

if "%choice%"=="1" (
    echo.
    echo Dang chay User App...
    echo.
    echo LUU Y: Phai accept SSL certificate truoc!
    echo Trong Chrome, mo tab moi: https://192.168.1.9:9443
    echo Advance -^> Proceed to 192.168.1.9 ^(unsafe^)
    echo.
    pause
    flutter run -d chrome -t lib/main_test.dart
) else if "%choice%"=="2" (
    echo.
    echo Dang chay Device Test...
    echo.
    echo LUU Y: 
    echo - Phai accept SSL certificate truoc
    echo - Nhap auth token tu web dashboard
    echo - Chon path: /websocket
    echo.
    pause
    flutter run -d chrome -t lib/main_device_test.dart
) else (
    echo.
    echo Lua chon khong hop le!
    pause
)
