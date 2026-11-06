@echo off
setlocal
set "PATH=D:\android-sdk\platform-tools;%PATH%"
echo.
echo  Menyalakan server API Laravel + meneruskan port ke HP...
echo.
start "Absensi API" /min cmd /c "cd /d D:\Absensi Bmt && php artisan serve --host=0.0.0.0 --port=8000"
timeout /t 3 /nobreak >nul
adb reverse tcp:8000 tcp:8000
echo.
echo  API jalan di jendela terpisah. Tutup jendela itu untuk mematikannya.
echo.
pause
endlocal
