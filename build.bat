@echo off
echo ================================
echo CYDS Blynk - Build Release
echo ================================
echo.

echo Choose build type:
echo 1. Web
echo 2. Android APK
echo 3. Android App Bundle
echo 4. Windows
echo 5. All platforms
echo.
set /p buildtype="Enter choice (1-5): "

if "%buildtype%"=="1" goto :web
if "%buildtype%"=="2" goto :android_apk
if "%buildtype%"=="3" goto :android_bundle
if "%buildtype%"=="4" goto :windows
if "%buildtype%"=="5" goto :all
goto :invalid

:web
echo Building for Web...
flutter build web --release
echo.
echo Build complete! Files are in: build\web
echo To serve: cd build\web ^&^& python -m http.server 8000
goto :end

:android_apk
echo Building Android APK...
flutter build apk --release --split-per-abi
echo.
echo Build complete! APK files are in: build\app\outputs\flutter-apk\
goto :end

:android_bundle
echo Building Android App Bundle...
flutter build appbundle --release
echo.
echo Build complete! Bundle is in: build\app\outputs\bundle\release\
goto :end

:windows
echo Building for Windows...
flutter build windows --release
echo.
echo Build complete! Executable is in: build\windows\runner\Release\
goto :end

:all
echo Building for all platforms...
echo.
echo [1/3] Building Web...
flutter build web --release
echo.
echo [2/3] Building Android APK...
flutter build apk --release --split-per-abi
echo.
echo [3/3] Building Windows...
flutter build windows --release
echo.
echo All builds complete!
echo - Web: build\web
echo - Android: build\app\outputs\flutter-apk\
echo - Windows: build\windows\runner\Release\
goto :end

:invalid
echo Invalid choice!
goto :end

:end
echo.
pause
