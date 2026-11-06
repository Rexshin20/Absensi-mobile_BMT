@echo off
setlocal
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.21.9-hotspot"
set "ANDROID_HOME=D:\android-sdk"
set "PATH=%JAVA_HOME%\bin;D:\flutter\bin;D:\android-sdk\platform-tools;%PATH%"

echo.
echo  [1/3] Menyalakan server API + adb reverse
echo.
start "Absensi API" /min cmd /c "cd /d D:\Absensi Bmt && php artisan serve --host=0.0.0.0 --port=8000"
timeout /t 3 /nobreak >nul
adb reverse tcp:8000 tcp:8000

echo.
echo  [2/3] Membangun APK debug (yang pertama kali paling lama)
echo.
cd /d D:\absensi-mobile
flutter build apk --debug
if errorlevel 1 goto gagal

echo.
echo  [3/3] Memasang ke HP dan membuka aplikasinya
echo.
adb install -r "D:\absensi-mobile\build\app\outputs\flutter-apk\app-debug.apk"
adb shell am start -n com.bmtcindebarokah.absensi_mobile/.MainActivity
echo.
echo  Selesai. Aplikasi seharusnya sudah terbuka di HP.
goto akhir

:gagal
echo.
echo  BUILD GAGAL. Copy baris "What went wrong" ke Qoder.

:akhir
echo.
pause
endlocal
