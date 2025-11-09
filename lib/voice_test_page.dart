import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'voice_alarm_service.dart';
import 'voice_recognition_service.dart';
import 'package:tfg_definitivo2/widgets/glass_navbar.dart';
import 'package:tfg_definitivo2/database_helper.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:tfg_definitivo2/env.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoiceTestPage extends StatefulWidget {
  const VoiceTestPage({super.key});

  @override
  State<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends State<VoiceTestPage> {
  final VoiceAlarmService _voiceService = VoiceAlarmService();
  final VoiceRecognitionService _recognitionService = VoiceRecognitionService();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusMessage = 'Inicializando...';
  String _recognizedText = '';
  String _partialText = ''; // Texto en tiempo real mientras se escucha
  VoiceAlarmData? _lastAlarmData;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Verificar API key
      final isApiKeyConfigured = await _voiceService.isApiKeyConfigured;
      if (!isApiKeyConfigured) {
        setState(() {
          _statusMessage = '⚠️ API Key no configurada. Ve a Ajustes para configurarla.';
          _isInitialized = false;
        });
        return;
      }

      // Inicializar reconocimiento de voz
      final initialized = await _recognitionService.initialize();
      setState(() {
        _isInitialized = initialized;
        _statusMessage = initialized 
          ? 'Presiona el micrófono y habla'
          : 'Error inicializando micrófono. Verifica los permisos.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isInitialized = false;
      });
    }
  }

  Future<void> _startVoiceCommand() async {
    if (!_isInitialized || _isListening || _isProcessing) return;

    setState(() {
      _isListening = true;
      _statusMessage = '🎤 Escuchando... Habla ahora';
      _recognizedText = '';
      _partialText = '';
      _lastAlarmData = null;
    });

    try {
      // Iniciar reconocimiento de voz con callback para resultados parciales
      final recognizedText = await _recognitionService.startListening(
        timeout: const Duration(seconds: 30),
        onPartialResult: (partialText) {
          // Actualizar texto parcial en tiempo real
          if (mounted) {
            setState(() {
              _partialText = partialText;
              _statusMessage = '🎤 Escuchando...';
            });
          }
        },
      );
      
      setState(() {
        _isListening = false;
        _partialText = ''; // Limpiar texto parcial
      });

      if (recognizedText != null && recognizedText.isNotEmpty) {
        setState(() {
          _recognizedText = recognizedText;
          _statusMessage = '🤖 Procesando con IA...';
          _isProcessing = true;
        });

        // Procesar con IA
        final alarmData = await _voiceService.processVoiceCommand(recognizedText);
        
        setState(() {
          _isProcessing = false;
        });
        
        if (alarmData != null && alarmData.location.isNotEmpty) {
          setState(() {
            _lastAlarmData = alarmData;
            _statusMessage = '✅ Comando procesado correctamente';
          });

          // Crear la alarma automáticamente
          await _createAlarmFromVoice(alarmData);
        } else {
          setState(() {
            _statusMessage = '❌ No se pudo procesar el comando. Intenta de nuevo.';
          });
        }
      } else {
        setState(() {
          _statusMessage = '❌ No se detectó voz. Intenta hablar más cerca del micrófono.';
        });
      }
    } catch (e) {
      setState(() {
        _isListening = false;
        _isProcessing = false;
        _partialText = '';
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  Future<void> _createAlarmFromVoice(VoiceAlarmData alarmData) async {
    try {
      // Buscar coordenadas de la ubicación usando Google Places API (más confiable)
      double? latitude;
      double? longitude;
      String address = alarmData.location;
      
      try {
        // Intentar primero con Google Places API
        final placesResult = await _searchLocationWithGooglePlaces(alarmData.location);
        if (placesResult != null) {
          latitude = placesResult['latitude'];
          longitude = placesResult['longitude'];
          address = placesResult['address'] ?? alarmData.location;
        } else {
          // Fallback a geocoding si Places API no funciona
          final locations = await geo.locationFromAddress(alarmData.location);
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
          }
        }
      } catch (e) {
        // Si falla, mostrar mensaje
        if (mounted) {
          setState(() {
            _statusMessage = '⚠️ Ubicación no encontrada. Intenta ser más específico (ej: "Madrid, España").';
          });
        }
        return;
      }

      if (latitude == null || longitude == null) {
        if (mounted) {
          setState(() {
            _statusMessage = '⚠️ Ubicación no encontrada. Intenta ser más específico.';
          });
        }
        return;
      }

      // Crear la alarma en la base de datos
      await DatabaseHelper.instance.insertAlarma({
        'nombre': alarmData.alarmName,
        'ubicacion': address,
        'latitud': latitude,
        'longitud': longitude,
        'rango': alarmData.range.toInt().toString(), // Asegurar que sea string
        'activa': 0,
      });

      if (mounted) {
        setState(() {
          _statusMessage = '✅ Alarma "${alarmData.alarmName}" creada exitosamente';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Alarma "${alarmData.alarmName}" creada exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Volver',
              textColor: Colors.white,
              onPressed: () {
                // Volver a HomePage y recargar alarmas
                Navigator.pop(context, true);
              },
            ),
          ),
        );
        
        // Limpiar los datos después de 5 segundos para permitir otro comando
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _recognizedText.isNotEmpty) {
            setState(() {
              _recognizedText = '';
              _lastAlarmData = null;
              _statusMessage = 'Presiona el micrófono y habla';
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '⚠️ Error creando alarma: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(theme),
                // Contenido principal
                Expanded(
                  child: _buildMainContent(theme),
                ),
                // Espacio para el navbar
                const SizedBox(height: 100),
              ],
            ),
          ),
          // Navbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassNavbar(
              currentIndex: 2, // Voz está en el índice 2
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Voz',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Botón de micrófono grande
          _buildMicrophoneButton(theme),
          
          const SizedBox(height: 32),
          
          // Mensaje de estado
          _buildStatusMessage(theme),
          
          const SizedBox(height: 24),
          
          // Texto en tiempo real mientras se escucha (transcripción parcial)
          if (_isListening && _partialText.isNotEmpty)
            _buildPartialText(theme),
          
          const SizedBox(height: 24),
          
          // Texto reconocido final
          if (_recognizedText.isNotEmpty)
            _buildRecognizedText(theme),
          
          const SizedBox(height: 24),
          
          // Datos de la alarma
          if (_lastAlarmData != null)
            _buildAlarmData(theme),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton(ThemeData theme) {
    final isActive = _isListening || _isProcessing;
    final canPress = _isInitialized && !isActive;
    
    return GestureDetector(
      onTap: canPress ? _startVoiceCommand : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    Colors.red[400]!,
                    Colors.red[600]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.red : theme.colorScheme.primary)
                  .withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: (isActive ? Colors.red : theme.colorScheme.primary)
                  .withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animación de ondas cuando está activo
            if (isActive)
              ...List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Container(
                      width: 180 + (value * 60 * (index + 1)),
                      height: 180 + (value * 60 * (index + 1)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isActive ? Colors.red : theme.colorScheme.primary)
                              .withOpacity(0.3 * (1 - value)),
                          width: 2,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    if (isActive && mounted) {
                      setState(() {});
                    }
                  },
                );
              }),
            
            // Icono o indicador de carga
            _isListening
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.mic_fill,
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escuchando...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : _isProcessing
                    ? const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 4,
                        ),
                      )
                    : Icon(
                        CupertinoIcons.mic,
                        size: 80,
                        color: Colors.white,
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage(ThemeData theme) {
    Color messageColor;
    IconData messageIcon;
    
    if (_statusMessage.contains('✅')) {
      messageColor = Colors.green;
      messageIcon = CupertinoIcons.check_mark_circled_solid;
    } else if (_statusMessage.contains('❌') || _statusMessage.contains('⚠️')) {
      messageColor = _statusMessage.contains('⚠️') ? Colors.orange : Colors.red;
      messageIcon = _statusMessage.contains('⚠️') 
          ? CupertinoIcons.exclamationmark_triangle_fill
          : CupertinoIcons.xmark_circle_fill;
    } else if (_statusMessage.contains('🎤')) {
      messageColor = Colors.blue;
      messageIcon = CupertinoIcons.mic_fill;
    } else if (_statusMessage.contains('🤖')) {
      messageColor = Colors.purple;
      messageIcon = CupertinoIcons.sparkles;
    } else {
      messageColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
      messageIcon = CupertinoIcons.info_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: messageColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: messageColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            messageIcon,
            color: messageColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _statusMessage,
              style: TextStyle(
                color: messageColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialText(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.mic_fill,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Escuchando...',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _partialText.toLowerCase(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognizedText(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Comando reconocido',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _recognizedText.toLowerCase(),
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmData(ThemeData theme) {
    if (_lastAlarmData == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.sparkles,
                color: Colors.purple[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Datos extraídos',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDataRow('📍 Ubicación', _lastAlarmData!.location, theme),
          const SizedBox(height: 12),
          _buildDataRow('📝 Nombre', _lastAlarmData!.alarmName, theme),
          const SizedBox(height: 12),
          _buildDataRow('📏 Rango', '${_lastAlarmData!.range.toInt()} metros', theme),
          const SizedBox(height: 12),
          _buildDataRow('🎯 Confianza', '${(_lastAlarmData!.confidence * 100).toInt()}%', theme),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }


  /// Busca una ubicación usando Google Places API
  Future<Map<String, dynamic>?> _searchLocationWithGooglePlaces(String query) async {
    try {
      final apiKey = googleMapsApiKey;
      final url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${Uri.encodeComponent(query)}&inputtype=textquery&fields=formatted_address,geometry&key=$apiKey&language=es';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['candidates'] != null && data['candidates'].isNotEmpty) {
        final candidate = data['candidates'][0];
        final geometry = candidate['geometry'];
        final location = geometry['location'];
        
        return {
          'latitude': location['lat'] as double,
          'longitude': location['lng'] as double,
          'address': candidate['formatted_address'] as String,
        };
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _recognitionService.dispose();
    super.dispose();
  }
}
