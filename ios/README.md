# WakeMap iOS Configuration

## Configuración Requerida para iOS

### 1. Permisos Configurados

La aplicación ya tiene configurados los siguientes permisos en `Info.plist`:

- **Ubicación**: Para crear y activar alarmas basadas en ubicación
- **Micrófono**: Para reconocimiento de voz
- **Notificaciones**: Para alertas de alarma
- **Background Modes**: Para funcionamiento en segundo plano

### 2. Google Maps Configuration

La aplicación está configurada para usar Google Maps con la API key:
```
AIzaSyB5Nc_EBy8tO9Wyh0K0B96RDkN9d-MET_4
```

### 3. Archivos de Audio

El archivo `alarma.mp3` está incluido en los recursos de la aplicación para las alarmas nativas.

### 4. Funcionalidades Nativas

#### AlarmViewController.swift
- Maneja las alarmas nativas de iOS
- Reproduce audio de alarma
- Interfaz nativa para detener la alarma
- Comunicación con Flutter a través de NotificationCenter

#### AppDelegate.swift
- Configuración de notificaciones
- Manejo de canales de método para comunicación con Flutter
- Gestión de permisos

### 5. Configuración de Build

#### Entitlements
- `Runner.entitlements`: Configuración de capacidades de ubicación y background modes

#### Project Configuration
- Versión mínima de iOS: 12.0
- Swift 5.0
- Configuración automática de code signing

### 6. Instrucciones de Build

1. Abrir el proyecto en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Configurar el equipo de desarrollo:
   - Seleccionar tu equipo de desarrollo en "Signing & Capabilities"
   - Asegurarse de que el Bundle Identifier sea único

3. Configurar capacidades:
   - Background Modes: Location updates, Background processing
   - Location Services: Always and When In Use

4. Build y ejecutar:
   ```bash
   flutter build ios
   flutter run
   ```

### 7. Testing

#### Dispositivo Físico
- Probar en dispositivo físico para verificar permisos de ubicación
- Verificar que las alarmas funcionen correctamente
- Comprobar que las notificaciones se muestren

#### Simulador
- Las funcionalidades de ubicación pueden ser limitadas
- Usar ubicaciones simuladas para testing

### 8. Troubleshooting

#### Problemas Comunes

1. **Permisos de ubicación no funcionan**:
   - Verificar que los permisos estén en Info.plist
   - Comprobar que la app solicite permisos al usuario

2. **Google Maps no carga**:
   - Verificar que la API key sea válida
   - Comprobar que Google Maps SDK esté habilitado

3. **Alarmas no suenan**:
   - Verificar que el archivo de audio esté incluido
   - Comprobar permisos de notificación

4. **Build errors**:
   - Limpiar build: `flutter clean`
   - Reinstalar pods: `cd ios && pod install`

### 9. Deployment

Para publicar en App Store:

1. Configurar certificados de distribución
2. Actualizar Bundle Identifier
3. Configurar App Store Connect
4. Generar build de release:
   ```bash
   flutter build ios --release
   ```

### 10. Notas Importantes

- La aplicación requiere iOS 12.0 o superior
- Los permisos de ubicación son obligatorios para el funcionamiento
- Las notificaciones deben estar habilitadas para las alarmas
- El archivo de audio debe estar incluido en el bundle de la aplicación
