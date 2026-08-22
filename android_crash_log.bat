@echo off
setlocal
cd /d "%~dp0"
echo USB hata ayiklama acik ve telefon kablo ile bagli olmalidir.
echo.
adb devices
echo.
echo Eski log temizleniyor...
adb logcat -c
echo MleySoft IK aciliyor...
adb shell monkey -p com.mleysoft.ik -c android.intent.category.LAUNCHER 1 >nul
echo.
echo Uygulama kapanirsa asagidaki AndroidRuntime/FATAL EXCEPTION satirlarini gonderin:
adb logcat -v time AndroidRuntime:E flutter:E WorkManager:E *:S
