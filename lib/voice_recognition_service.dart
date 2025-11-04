import 'package:flutter/material.dart';
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

  /// Inicia el reconocimiento de voz
  Future<String?> startListening({
    Duration timeout = const Duration(seconds: 10),
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
      
      String? result;
      bool completed = false;

      await _speech.listen(
        onResult: (speechResult) {
          _logger.d('🎤 Texto reconocido: ${speechResult.recognizedWords}');
          _logger.d('🎤 Es resultado final: ${speechResult.finalResult}');
          _logger.d('🎤 Confianza: ${speechResult.confidence}');
          
          // Aceptar resultado si tiene confianza mínima o es resultado final
          if (speechResult.finalResult || speechResult.confidence > 0.5) {
            result = speechResult.recognizedWords;
            completed = true;
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 5), // Más tiempo para pausas
        partialResults: true,
        localeId: 'es', // Usar 'es' en lugar de 'es_ES'
        listenMode: stt.ListenMode.dictation, // Cambiar a dictation
      );

      // Esperar hasta que termine o se agote el tiempo
      int attempts = 0;
      while (!completed && attempts < (timeout.inSeconds * 10) && _isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      await _speech.stop();
      
      if (result != null && result!.isNotEmpty) {
        _logger.d('🎤 Reconocimiento finalizado. Resultado: $result');
        return result;
      } else {
        _logger.d('🎤 No se detectó voz o timeout alcanzado');
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
