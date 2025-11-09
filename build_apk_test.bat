@echo off
REM Script simple para construir APK de prueba con la API key ya configurada
REM La API key debe estar configurada en lib/env.dart en _defaultGeminiApiKey

echo 🚀 Construyendo APK de prueba...
echo.

REM Verificar que Flutter esté instalado
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter no está instalado o no está en el PATH
    exit /b 1
)

echo 📦 Limpiando builds anteriores...
call flutter clean

echo 📥 Obteniendo dependencias...
call flutter pub get

echo.
echo 📱 Construyendo APK de prueba (release)...
call flutter build apk --release

echo.
echo ✅ APK construido exitosamente!
echo.
echo 📁 Archivo generado: build\app\outputs\flutter-apk\app-release.apk
echo.
echo 💡 Instrucciones:
echo   1. Conecta tu dispositivo Android por USB
echo   2. Activa "Depuración USB" en opciones de desarrollador
echo   3. Ejecuta: flutter install
echo   4. O transfiere el APK manualmente al dispositivo
echo.
echo ⚠️  Nota: Asegúrate de tener la API key configurada en lib/env.dart
echo    (variable _defaultGeminiApiKey) para que funcione correctamente

