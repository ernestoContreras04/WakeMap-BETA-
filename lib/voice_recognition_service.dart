import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class VoiceRecognitionService {
  static final VoiceRecognitionService _instance = VoiceRecognitionService._internal();
  factory VoiceRecognitionService() => _instance;
  VoiceRecognitionService._internal();

  final Logger _logger = Logger();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;

  /// Inicializa el servicio de reconocimiento de voz
  Future<bool> initialize() async {
    try {
      _logger.d('🎤 Inicializando reconocimiento de voz...');
      
      // Solicitar permisos de micrófono
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        _logger.e('❌ Permiso de micrófono denegado');
        return false;
      }

      // Inicializar speech_to_text
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          _logger.d('🎤 Estado del reconocimiento: $status');
          _isListening = status == 'listening';
        },
        onError: (error) {
          _logger.d('🎤 Error en reconocimiento: ${error.errorMsg}');
          // No tratamos todos los errores como críticos
          if (error.errorMsg != 'error_speech_timeout') {
            _logger.e('❌ Error crítico en reconocimiento: ${error.errorMsg}');
          }
        },
      );

      if (_isInitialized) {
        _logger.d('✅ Reconocimiento de voz inicializado correctamente');
        
        // Mostrar idiomas disponibles
        final locales = await _speech.locales();
        _logger.d('🌍 Idiomas disponibles: ${locales.map((l) => '${l.localeId} (${l.name})').toList()}');
      } else {
        _logger.e('❌ Error inicializando reconocimiento de voz');
      }

      return _isInitialized;
    } catch (e) {
      _logger.e('❌ Error inicializando servicio de voz: $e');
      return false;
    }
  }

  /// Verifica si el reconocimiento de voz está disponible
  bool get isAvailable => _isInitialized && _speech.isAvailable;

  /// Verifica si está escuchando actualmente
  bool get isListening => _isListening;

  /// Inicia el reconocimiento de voz con callback para resultados parciales
  Future<String?> startListening({
    Duration timeout = const Duration(seconds: 30),
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      _logger.e('❌ Servicio no inicializado');
      return null;
    }

    if (_isListening) {
      _logger.e('❌ Ya está escuchando');
      return null;
    }

    try {
      _logger.d('🎤 Iniciando reconocimiento de voz...');
      
      // Verificar idiomas disponibles y usar el mejor disponible
      final locales = await _speech.locales();
      String? localeId = 'es_ES';
      
      // Intentar encontrar el mejor locale en español
      final spanishLocales = locales.where((l) => 
        l.localeId.startsWith('es')).toList();
      if (spanishLocales.isNotEmpty) {
        // Preferir es_ES, luego es_MX, luego cualquier otro español
        localeId = spanishLocales.firstWhere(
          (l) => l.localeId == 'es_ES',
          orElse: () => spanishLocales.firstWhere(
            (l) => l.localeId == 'es_MX',
            orElse: () => spanishLocales.first,
          ),
        ).localeId;
      } else if (locales.any((l) => l.localeId == 'es')) {
        localeId = 'es';
      } else {
        localeId = null; // Usar el predeterminado del sistema
      }
      
      _logger.d('🎤 Usando locale: $localeId');
      
      String? finalResult;
      final completer = Completer<String?>();
      
      bool hasReceivedAnyResult = false;

      await _speech.listen(
        onResult: (speechResult) {
          final words = speechResult.recognizedWords;
          final isFinal = speechResult.finalResult;
          
          _logger.d('🎤 Texto: "$words" | Final: $isFinal | Confianza: ${speechResult.confidence}');
          
          // Siempre mostrar resultados parciales
          if (words.isNotEmpty) {
            hasReceivedAnyResult = true;
            finalResult = words; // Guardar siempre el último resultado (parcial o final)
            
            // Llamar callback con resultados parciales
            if (onPartialResult != null) {
              onPartialResult(words);
            }
          }
          
          // Si es resultado final y tiene contenido, completar
          if (isFinal && words.isNotEmpty) {
            _logger.d('🎤 Resultado final recibido: $finalResult');
            if (!completer.isCompleted) {
              completer.complete(finalResult);
            }
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 2), // Reducido para mejor respuesta
        partialResults: true,
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        onSoundLevelChange: (level) {
          // Log cuando hay sonido para debugging
          if (level > 0.01) {
            _logger.d('🎤 Nivel de sonido: ${level.toStringAsFixed(2)}');
          }
        },
      );
      
      _logger.d('🎤 Reconocimiento iniciado, esperando resultados...');

      // Esperar el resultado con timeout
      // Si no hay resultado final después del timeout, usar el último resultado parcial
      try {
        // Esperar a que el reconocimiento termine o timeout
        Timer? timeoutTimer;
        bool isCompleted = false;
        
        timeoutTimer = Timer(timeout + const Duration(seconds: 2), () {
          if (!isCompleted && !completer.isCompleted) {
            _logger.d('🎤 Timeout esperando resultado final, usando último resultado parcial');
            completer.complete(finalResult);
          }
        });
        
        final result = await completer.future;
        isCompleted = true;
        timeoutTimer.cancel();
        
        // Detener el reconocimiento
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (result != null && result.isNotEmpty) {
          _logger.d('🎤 Reconocimiento finalizado. Resultado: $result');
          return result;
        } else if (hasReceivedAnyResult && finalResult != null && finalResult!.isNotEmpty) {
          _logger.d('🎤 Usando último resultado parcial: $finalResult');
          return finalResult;
        } else {
          _logger.d('🎤 No se detectó voz o no hubo resultados');
          return null;
        }
      } catch (e) {
        _logger.e('❌ Error esperando resultado: $e');
        await _speech.stop();
        // Si tenemos algún resultado, usarlo
        if (finalResult != null && finalResult!.isNotEmpty) {
          return finalResult;
        }
        return null;
      }
      
    } catch (e) {
      _logger.e('❌ Error durante reconocimiento: $e');
      await _speech.stop();
      return null;
    }
  }

  /// Detiene el reconocimiento de voz
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _logger.d('🎤 Reconocimiento detenido');
      }
    } catch (e) {
      _logger.e('❌ Error deteniendo reconocimiento: $e');
    }
  }

  /// Obtiene los idiomas disponibles
  Future<List<stt.LocaleName>> get availableLocales => _speech.locales();

  /// Verifica si un idioma específico está disponible
  Future<bool> isLocaleAvailable(String localeId) async {
    final locales = await _speech.locales();
    return locales.any((locale) => locale.localeId == localeId);
  }

  /// Limpia recursos
  void dispose() {
    _speech.cancel();
  }
}
