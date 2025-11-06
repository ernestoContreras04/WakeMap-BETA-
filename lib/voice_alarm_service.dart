import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'env.dart';

class VoiceAlarmService {
  static final VoiceAlarmService _instance = VoiceAlarmService._internal();
  factory VoiceAlarmService() => _instance;
  VoiceAlarmService._internal();

  final Logger _logger = Logger();
  final String _apiKey = geminiApiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// Procesa un comando de voz y extrae información de alarma
  Future<VoiceAlarmData?> processVoiceCommand(String voiceText) async {
    try {
      _logger.d('🎤 Procesando comando de voz: $voiceText');

      // Preparar el prompt para Gemini
      final prompt = _createPrompt(voiceText);
      
      // Llamar a la API de Gemini
      final response = await _callGeminiAPI(prompt);
      
      if (response != null) {
        // Parsear la respuesta
        final alarmData = _parseGeminiResponse(response);
        _logger.d('✅ Datos extraídos: $alarmData');
        return alarmData;
      }
      
      return null;
    } catch (e) {
      _logger.e('❌ Error procesando comando de voz: $e');
      return null;
    }
  }

  /// Crea el prompt optimizado para Gemini
  String _createPrompt(String voiceText) {
    return '''
Analiza: "$voiceText"

Responde SOLO JSON:
{
  "location": "ubicación mencionada",
  "locationType": "ciudad|lugar_especifico|lugar_personalizado", 
  "range": 100,
  "alarmName": "nombre corto",
  "isValid": true,
  "confidence": 0.9
}

Reglas:
- "cuando llegue" = proximidad
- Rango por defecto: 100m
- Ciudades = "ciudad"
- Trabajo/casa = "lugar_personalizado"
''';
  }

  /// Lista los modelos disponibles
  Future<List<String>> _listAvailableModels() async {
    try {
      final url = '$_baseUrl/models?key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        final modelNames = models.map((m) => m['name'] as String).toList();
        _logger.d('🤖 Modelos disponibles: $modelNames');
        return modelNames;
      }
      return [];
    } catch (e) {
      _logger.e('❌ Error listando modelos: $e');
      return [];
    }
  }

  /// Llama a la API de Gemini
  Future<String?> _callGeminiAPI(String prompt) async {
    try {
  // Usar gemini-2.0-flash-lite según preferencia del proyecto
  final url = '$_baseUrl/models/gemini-2.0-flash-lite:generateContent?key=$_apiKey';
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      _logger.d('📡 Status Code: ${response.statusCode}');
      _logger.d('📡 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('📡 Parsed Data: $data');
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          _logger.d('📡 Candidate: $candidate');
          
          if (candidate['content'] != null && candidate['content']['parts'] != null && candidate['content']['parts'].isNotEmpty) {
            final content = candidate['content']['parts'][0]['text'];
            _logger.d('🤖 Respuesta de Gemini: $content');
            return content;
          } else if (candidate['finishReason'] == 'MAX_TOKENS') {
            _logger.e('❌ Modelo alcanzó límite de tokens. Finish reason: ${candidate['finishReason']}');
            return null;
          } else {
            _logger.e('❌ Estructura de contenido inválida: ${candidate['content']}');
            return null;
          }
        } else {
          _logger.e('❌ No hay candidates en la respuesta: ${data['candidates']}');
          return null;
        }
      } else {
        _logger.e('❌ Error API Gemini: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error llamando API Gemini: $e');
      return null;
    }
  }

  /// Parsea la respuesta de Gemini
  VoiceAlarmData? _parseGeminiResponse(String response) {
    try {
      // Limpiar la respuesta (remover markdown si existe)
      String cleanResponse = response.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final data = jsonDecode(cleanResponse);
      
      if (data['isValid'] == true) {
        return VoiceAlarmData(
          location: data['location'] ?? '',
          locationType: data['locationType'] ?? 'lugar_personalizado',
          range: data['range']?.toDouble() ?? 100.0,
          alarmName: data['alarmName'] ?? 'Alarma por voz',
          confidence: data['confidence']?.toDouble() ?? 0.0,
        );
      }
      
      return null;
    } catch (e) {
      _logger.e('❌ Error parseando respuesta: $e');
      return null;
    }
  }

  /// Prueba la conexión con Gemini
  Future<bool> testConnection() async {
    try {
      _logger.d('🧪 Probando conexión con Gemini...');
      
      // Primero listar modelos disponibles
      final models = await _listAvailableModels();
      if (models.isEmpty) {
        _logger.e('❌ No se pudieron obtener modelos disponibles');
        return false;
      }
      
      // Probar con un comando simple
      final result = await processVoiceCommand('Ponme una alarma para cuando llegue a Madrid');
      return result != null;
    } catch (e) {
      _logger.e('❌ Error en test de conexión: $e');
      return false;
    }
  }
}

/// Clase para almacenar los datos extraídos de la alarma por voz
class VoiceAlarmData {
  final String location;
  final String locationType;
  final double range;
  final String alarmName;
  final double confidence;

  VoiceAlarmData({
    required this.location,
    required this.locationType,
    required this.range,
    required this.alarmName,
    required this.confidence,
  });

  @override
  String toString() {
    return 'VoiceAlarmData(location: $location, locationType: $locationType, range: $range, alarmName: $alarmName, confidence: $confidence)';
  }
}
