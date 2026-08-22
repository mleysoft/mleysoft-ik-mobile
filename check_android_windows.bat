@echo off
setlocal
cd /d "%~dp0"

echo [1/4] Flutter doctor
call flutter doctor
if errorlevel 1 goto :fail

echo [2/4] Dependencies
call flutter pub get
if errorlevel 1 goto :fail

echo [3/4] Dart / Flutter analyze
call flutter analyze
if errorlevel 1 goto :fail

echo [4/4] Connected devices
call flutter devices
echo.
echo Kontrol tamamlandi.
exit /b 0

:fail
echo.
echo Kontrol sirasinda hata olustu.
exit /b 1
