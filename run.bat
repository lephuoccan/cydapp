@echo off
echo ================================
echo CYDS Blynk - Setup and Run
echo ================================
echo.

echo [1/4] Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)

echo.
echo [2/4] Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo [3/4] Running Flutter doctor...
flutter doctor

echo.
echo [4/4] Starting application...
echo.
echo Choose platform:
echo 1. Web (Chrome)
echo 2. Windows Desktop
echo 3. Android
echo 4. iOS
echo.
set /p platform="Enter choice (1-4): "

if "%platform%"=="1" (
    echo Starting on Chrome...
    flutter run -d chrome
) else if "%platform%"=="2" (
    echo Starting on Windows...
    flutter run -d windows
) else if "%platform%"=="3" (
    echo Starting on Android...
    flutter run -d android
) else if "%platform%"=="4" (
    echo Starting on iOS...
    flutter run -d ios
) else (
    echo Invalid choice. Starting on Chrome by default...
    flutter run -d chrome
)

pause
