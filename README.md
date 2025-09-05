# WakeMap

Una aplicación Flutter para crear alarmas basadas en ubicación geográfica.

## Descripción

WakeMap es una aplicación móvil que permite a los usuarios crear alarmas que se activan cuando entran en un radio específico alrededor de una ubicación determinada. La aplicación incluye funcionalidades como mapas interactivos, información del clima, y alarmas con audio.

## Características

- 🗺️ **Mapas Interactivos**: Integración con Google Maps
- 📍 **Alarmas Geográficas**: Crear alarmas basadas en ubicación
- 🌤️ **Información del Clima**: Temperatura y velocidad del viento
- 🔊 **Alarmas con Audio**: Reproducción de sonidos de alarma
- 🎤 **Reconocimiento de Voz**: Comandos de voz
- 📱 **Notificaciones**: Alertas locales
- 💾 **Almacenamiento Local**: Base de datos SQLite

## Plataformas Soportadas

- ✅ **Android**: Completamente funcional
- ✅ **iOS**: Configurado y listo para usar
- ✅ **Web**: Soporte básico
- ✅ **Windows/macOS/Linux**: Soporte de escritorio

## Configuración

### Requisitos Previos

- Flutter SDK 3.7.2 o superior
- Dart SDK
- Android Studio / Xcode (para desarrollo móvil)
- Cuenta de Google Cloud (para Google Maps API)

### Instalación

1. Clonar el repositorio:
   ```bash
   git clone <repository-url>
   cd WakeMap-BETA-
   ```

2. Instalar dependencias:
   ```bash
   flutter pub get
   ```

3. Configurar API Keys:
   - Google Maps API Key: Ya configurada en el proyecto
   - Open-Meteo API: No requiere configuración

### Configuración de Android

La aplicación ya está configurada para Android con:
- Permisos de ubicación
- Configuración de Google Maps
- Actividad nativa para alarmas
- Configuración de red

### Configuración de iOS

Ver el archivo `ios/README.md` para instrucciones detalladas de configuración de iOS.

## Uso

1. **Crear Alarma**:
   - Toca el botón "+" para crear una nueva alarma
   - Selecciona la ubicación en el mapa
   - Define el radio de activación
   - Asigna un nombre a la alarma

2. **Gestionar Alarmas**:
   - Ver todas las alarmas en la pantalla principal
   - Editar alarmas existentes
   - Activar/desactivar alarmas

3. **Alarmas**:
   - Las alarmas se activan automáticamente al entrar en la zona
   - Reproducción de audio de alarma
   - Interfaz nativa para detener la alarma

## Estructura del Proyecto

```
lib/
├── main.dart                 # Aplicación principal
├── create_alarma_page.dart   # Crear alarmas
├── edit_alarma.dart         # Editar alarmas
├── database_helper.dart      # Base de datos
├── autocompletado.dart      # Autocompletado de ubicaciones
└── utils/
    └── polyline_decoder.dart # Utilidades de mapas

assets/
├── audios/
│   └── alarma.mp3          # Sonido de alarma
├── fonts/                  # Fuentes personalizadas
└── images/
    └── icono.png          # Icono de la app
```

## Dependencias Principales

- `google_maps_flutter`: Mapas de Google
- `location`: Geolocalización
- `sqflite`: Base de datos local
- `flutter_local_notifications`: Notificaciones
- `audioplayers`: Reproducción de audio
- `speech_to_text`: Reconocimiento de voz

## Desarrollo

### Comandos Útiles

```bash
# Ejecutar en Android
flutter run

# Ejecutar en iOS
flutter run -d ios

# Build de release para Android
flutter build apk --release

# Build de release para iOS
flutter build ios --release

# Limpiar proyecto
flutter clean
```

### Testing

```bash
# Ejecutar tests
flutter test

# Análisis de código
flutter analyze
```

## Deployment

### Android
1. Generar APK: `flutter build apk --release`
2. Firmar APK para Google Play Store
3. Subir a Google Play Console

### iOS
1. Configurar certificados en Xcode
2. Generar build: `flutter build ios --release`
3. Subir a App Store Connect

## Contribución

1. Fork el proyecto
2. Crear rama para feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Agregar nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

## Licencia

Este proyecto es parte de un Trabajo de Fin de Grado (TFG).

## Soporte

Para soporte técnico o preguntas, contactar al desarrollador del proyecto.
