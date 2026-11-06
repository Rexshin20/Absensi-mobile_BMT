@echo off
setlocal
set "PATH=D:\android-sdk\platform-tools;%PATH%"
echo.
echo  Memasang APK ke HP... (kalau HP nanya "Install via USB?", pencet Allow)
echo.
adb devices
adb install -r "D:\absensi-mobile\build\app\outputs\flutter-apk\app-debug.apk"
echo.
echo  Membuka aplikasinya di HP...
adb shell am start -n com.bmtcindebarokah.absensi_mobile/.MainActivity
echo.
pause
endlocal
