# Instrucciones para Probar la App Web

## Opción 1: Ejecutar en modo desarrollo (Recomendado para pruebas)

Ejecuta la aplicación en Chrome con hot reload:

```bash
flutter run -d chrome
```

O si prefieres Edge:

```bash
flutter run -d edge
```

Esto:
- Compila y ejecuta la aplicación en el navegador
- Habilita hot reload para cambios en tiempo real
- Muestra logs en la consola
- Es ideal para desarrollo y pruebas

## Opción 2: Ejecutar en modo release (Para pruebas de rendimiento)

Para una versión optimizada similar a producción:

```bash
flutter run -d chrome --release
```

## Opción 3: Construir para producción

Para generar los archivos estáticos de la aplicación web:

```bash
flutter build web
```

Los archivos se generarán en la carpeta `build/web/`. 

### Servir los archivos localmente

Puedes usar cualquier servidor web local. Algunas opciones:

#### Con Python (si tienes Python instalado):
```bash
cd build/web
python -m http.server 8000
```

Luego abre en el navegador: `http://localhost:8000`

#### Con Node.js (si tienes Node.js instalado):
```bash
npx http-server build/web -p 8000
```

Luego abre en el navegador: `http://localhost:8000`

#### Con Flutter (servidor de desarrollo):
```bash
flutter run -d chrome --web-port 8080
```

## Verificación de Funcionalidades

Una vez que la app esté corriendo, verifica:

1. **Permisos del Navegador**:
   - Cuando la app solicite ubicación, acepta el permiso
   - Cuando uses comandos de voz, acepta el permiso del micrófono

2. **Funcionalidades Principales**:
   - ✅ Crear alarmas (deberían persistir al recargar)
   - ✅ Ubicaciones personalizadas (deberían persistir al recargar)
   - ✅ Comandos de voz
   - ✅ Mapas interactivos
   - ✅ Detección de proximidad
   - ✅ Sonidos de alarma

3. **Persistencia de Datos**:
   - Crea algunas alarmas
   - Recarga la página (F5)
   - Verifica que las alarmas siguen ahí

## Solución de Problemas

### Si no aparece Chrome en los dispositivos:
```bash
flutter config --enable-web
flutter doctor
```

### Si hay errores de compilación:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Si los permisos no funcionan:
- Asegúrate de usar HTTPS o localhost (navegadores modernos requieren contexto seguro para algunos permisos)
- Verifica la configuración de permisos en el navegador

### Para ver los logs:
- Abre la consola del navegador (F12)
- O ejecuta con: `flutter run -d chrome --verbose`

## Notas Importantes

- **HTTPS**: Algunas funcionalidades (como geolocalización y micrófono) requieren HTTPS en producción. En desarrollo, localhost funciona sin HTTPS.

- **API Keys**: Las API keys de Google Maps y Gemini deben estar configuradas correctamente (ver `lib/env.dart` y `web/index.html`).

- **Rendimiento**: La primera compilación puede tardar varios minutos. Las siguientes serán más rápidas gracias al caché.

