# 📱 Cómo Construir APK de Prueba con API Key Incluida

## Opción 1: Configurar la API Key en el Código (Más Rápido)

1. **Abre el archivo `lib/env.dart`**

2. **Busca la línea 36** que dice:
   ```dart
   const String _defaultGeminiApiKey = ''; // Pega tu API key aquí
   ```

3. **Pega tu API key de Gemini** entre las comillas:
   ```dart
   const String _defaultGeminiApiKey = 'AIzaSy...tu_clave_aqui';
   ```

4. **Construye el APK** usando uno de estos métodos:

   **Windows:**
   ```cmd
   build_apk_test.bat
   ```
   
   **Linux/Mac:**
   ```bash
   ./build_apk_test.sh
   ```
   
   **O manualmente:**
   ```bash
   flutter build apk --release
   ```

5. **El APK estará en:** `build/app/outputs/flutter-apk/app-release.apk`

## Opción 2: Usar Variable de Entorno (Más Seguro)

Si prefieres no poner la clave en el código:

```bash
# Windows
set GEMINI_API_KEY=tu_clave_aqui
flutter build apk --release --dart-define=GEMINI_API_KEY=%GEMINI_API_KEY%

# Linux/Mac
export GEMINI_API_KEY=tu_clave_aqui
flutter build apk --release --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
```

## ⚠️ IMPORTANTE

- **Para desarrollo/testing local**: Puedes poner la clave en `lib/env.dart` temporalmente
- **Para producción/Play Store**: DEJAR VACÍO `_defaultGeminiApiKey` y usar `--dart-define`
- **NUNCA** subas el archivo `lib/env.dart` con una clave real a un repositorio público
- Si ya pusiste una clave, asegúrate de que `lib/env.dart` esté en `.gitignore` o revierte los cambios antes de hacer commit

## 📲 Instalar el APK en tu Dispositivo

1. **Conecta tu dispositivo Android por USB**
2. **Activa "Depuración USB"** en Opciones de Desarrollador
3. **Instala directamente:**
   ```bash
   flutter install
   ```
   
   **O transfiere el APK manualmente:**
   - Copia `build/app/outputs/flutter-apk/app-release.apk` a tu dispositivo
   - Abre el archivo en tu dispositivo y permite la instalación desde fuentes desconocidas

## ✅ Verificar que Funciona

1. Abre la app en tu dispositivo
2. Ve a la pestaña **"Voz"**
3. Haz clic en **"Probar Conexión Gemini"**
4. Deberías ver un mensaje de éxito ✅

