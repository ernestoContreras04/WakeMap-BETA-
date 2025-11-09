import 'package:shared_preferences/shared_preferences.dart';
// Importar API key desde archivo de secretos (está en .gitignore, NO se sube a GitHub)
import 'env.secrets.dart' as secrets;

// Google Maps API key.
// Prefer supplying this at build time with: --dart-define=GOOGLE_MAPS_API_KEY=<key>
// The default value below matches the previous inline key so existing runs keep working,
// but you should rotate and remove the hardcoded value for security.
final String googleMapsApiKey = const String.fromEnvironment(
	'GOOGLE_MAPS_API_KEY',
	defaultValue: 'AIzaSyB5Nc_EBy8tO9Wyh0K0B96RDkN9d-MET_4',
);

// Gemini API key used to call the Generative Language API.
// IMPORTANTE: La clave anterior fue reportada como filtrada. DEBES usar una nueva clave.
//
// La API key se puede configurar de tres formas (en orden de prioridad):
// 1. Variable de entorno en el build (--dart-define) - PARA PRODUCCIÓN/PLAY STORE
// 2. Desde SharedPreferences (configurada en la app) - Para usuarios avanzados
// 3. Valor por defecto hardcodeado (solo para desarrollo, NO usar en producción)
//
// Para builds de producción (Play Store):
// flutter build apk --release --dart-define=GEMINI_API_KEY=tu_clave_produccion
// flutter build appbundle --release --dart-define=GEMINI_API_KEY=tu_clave_produccion
//
// Para obtener una nueva clave de API de Gemini:
// 1. Ve a https://makersuite.google.com/app/apikey
// 2. Crea una nueva API key
// 3. Configúrala en el build de producción usando --dart-define

// API KEY POR DEFECTO - Se carga desde env.secrets.dart (NO se sube a GitHub)
// ✅ FUNCIONARÁ PARA:
//    - flutter run (emulador/dispositivo)
//    - APK de prueba local (flutter build apk --release)
//
// 📍 CONFIGURACIÓN:
// La API key se carga desde lib/env.secrets.dart
// Este archivo está en .gitignore y NO se subirá a GitHub
// Tu API key está segura y no se expondrá en el repositorio
const String _defaultGeminiApiKey = secrets.defaultGeminiApiKey;

/// Obtiene la API key de Gemini con el siguiente orden de prioridad:
/// 1. Variable de entorno del build (--dart-define) - PARA PRODUCCIÓN
/// 2. SharedPreferences (configurada manualmente en la app)
/// 3. Valor por defecto (solo desarrollo)
Future<String> getGeminiApiKey() async {
  try {
    // Prioridad 1: Variable de entorno del build (--dart-define)
    // Esta es la forma correcta para builds de producción/Play Store
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    // Prioridad 2: SharedPreferences (para usuarios avanzados que quieran cambiarla)
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString('gemini_api_key');
    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }
    
    // Prioridad 3: Valor por defecto (solo para desarrollo)
    // En producción, esto debería estar vacío y usar --dart-define
    if (_defaultGeminiApiKey.isNotEmpty) {
      return _defaultGeminiApiKey;
    }
    
    // No hay clave configurada
    return '';
  } catch (e) {
    // Si hay error, intentar con variable de entorno
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    return _defaultGeminiApiKey;
  }
}

/// Guarda la API key de Gemini en SharedPreferences
Future<void> setGeminiApiKey(String apiKey) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('gemini_api_key', apiKey);
}

/// Elimina la API key de Gemini de SharedPreferences
Future<void> clearGeminiApiKey() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('gemini_api_key');
}

// Mantener esta constante para compatibilidad, pero ahora es asíncrona
// Se recomienda usar getGeminiApiKey() en su lugar
final String geminiApiKey = const String.fromEnvironment(
	'GEMINI_API_KEY',
	defaultValue: '', // Sin clave por defecto por seguridad
);