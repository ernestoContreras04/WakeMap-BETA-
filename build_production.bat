@echo off
REM Script para construir la aplicación para producción (Play Store) en Windows
REM Este script configura la API key de Gemini automáticamente

echo 🚀 Script de Build para Producción - WakeMap
echo.

REM Verificar que la API key esté configurada
if "%GEMINI_API_KEY%"=="" (
    echo ⚠️  Advertencia: Variable GEMINI_API_KEY no está configurada
    echo.
    echo Por favor, configura tu API key de Gemini:
    echo   set GEMINI_API_KEY=tu_clave_aqui
    echo.
    echo O pásala directamente al script:
    echo   set GEMINI_API_KEY=tu_clave ^&^& build_production.bat
    echo.
    set /p CONTINUE="¿Deseas continuar sin API key? (s/N): "
    if /i not "%CONTINUE%"=="s" (
        echo ❌ Build cancelado
        exit /b 1
    )
)

REM Verificar que Flutter esté instalado
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter no está instalado o no está en el PATH
    exit /b 1
)

echo 📦 Iniciando build de producción...
echo.

REM Limpiar builds anteriores
echo 🧹 Limpiando builds anteriores...
call flutter clean

REM Obtener dependencias
echo 📥 Obteniendo dependencias...
call flutter pub get

REM Build para Android (APK)
echo.
echo 📱 Construyendo APK para Android...
if "%GEMINI_API_KEY%"=="" (
    call flutter build apk --release
) else (
    call flutter build apk --release --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%
)

REM Build para Android (App Bundle - para Play Store)
echo.
echo 📦 Construyendo App Bundle para Play Store...
if "%GEMINI_API_KEY%"=="" (
    call flutter build appbundle --release
) else (
    call flutter build appbundle --release --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%
)

echo.
echo ✅ Build completado exitosamente!
echo.
echo 📁 Archivos generados:
echo   - APK: build\app\outputs\flutter-apk\app-release.apk
echo   - App Bundle: build\app\outputs\bundle\release\app-release.aab
echo.
echo ⚠️  Recuerda:
echo   1. Firmar el APK/App Bundle antes de subirlo a Play Store
echo   2. Verificar que la API key esté correctamente configurada
echo   3. Probar la app antes de publicar

