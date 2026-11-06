@echo off
setlocal
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.21.9-hotspot"
set "ANDROID_HOME=D:\android-sdk"
set "PATH=%JAVA_HOME%\bin;D:\flutter\bin;D:\android-sdk\platform-tools;%PATH%"
cd /d D:\absensi-mobile
echo.
echo  Membangun APK debug... (jendela ini tetap terbuka sampai selesai)
echo.
flutter build apk --debug
echo.
echo  Selesai dengan kode %ERRORLEVEL%. Tutup jendela ini untuk berhenti.
endlocal
