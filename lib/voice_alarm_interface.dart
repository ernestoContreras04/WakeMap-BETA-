import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'voice_alarm_service.dart';
import 'voice_recognition_service.dart';

class VoiceAlarmInterface extends StatefulWidget {
  final Function(VoiceAlarmData)? onAlarmCreated;

  const VoiceAlarmInterface({
    super.key,
    this.onAlarmCreated,
  });

  @override
  State<VoiceAlarmInterface> createState() => _VoiceAlarmInterfaceState();
}

class _VoiceAlarmInterfaceState extends State<VoiceAlarmInterface> {
  final VoiceAlarmService _voiceService = VoiceAlarmService();
  final VoiceRecognitionService _recognitionService = VoiceRecognitionService();
  final Logger _logger = Logger();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = '';
  String _recognizedText = '';
  VoiceAlarmData? _lastAlarmData;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _statusMessage = 'Inicializando servicios...';
    });

    try {
      final initialized = await _recognitionService.initialize();
      
      setState(() {
        _isInitialized = initialized;
        _statusMessage = initialized 
          ? 'Servicios listos. Presiona el micrófono para hablar.'
          : 'Error inicializando servicios de voz.';
      });

      if (initialized) {
        _logger.d('✅ Servicios de voz inicializados correctamente');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      _logger.e('❌ Error inicializando servicios: $e');
    }
  }

  Future<void> _startVoiceCommand() async {
    if (!_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Escuchando... Habla ahora.';
      _recognizedText = '';
      _lastAlarmData = null;
    });

    try {
      // Iniciar reconocimiento de voz
      final recognizedText = await _recognitionService.startListening();
      
      if (recognizedText != null && recognizedText.isNotEmpty) {
        setState(() {
          _recognizedText = recognizedText;
          _statusMessage = 'Procesando comando con IA...';
        });

        // Procesar con IA
        final alarmData = await _voiceService.processVoiceCommand(recognizedText);
        
        if (alarmData != null) {
          setState(() {
            _lastAlarmData = alarmData;
            _statusMessage = '¡Comando procesado exitosamente!';
          });

          // Llamar callback si existe
          widget.onAlarmCreated?.call(alarmData);
          
          _logger.d('✅ Alarma creada por voz: $alarmData');
        } else {
          setState(() {
            _statusMessage = 'No se pudo procesar el comando. Intenta de nuevo.';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'No se detectó voz o timeout. Intenta hablar más cerca del micrófono.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      _logger.e('❌ Error procesando comando de voz: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Estado de inicialización
          if (!_isInitialized)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          if (_isInitialized) ...[
            // Botón principal de micrófono
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isProcessing
                    ? LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.8),
                          Colors.red.withOpacity(0.4),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (_isProcessing ? Colors.red : Theme.of(context).colorScheme.primary)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(60),
                  onTap: _isProcessing ? null : _startVoiceCommand,
                  child: Center(
                    child: _isProcessing
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.mic,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Mensaje de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),

            // Texto reconocido
            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.record_voice_over, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Comando reconocido:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$_recognizedText"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Datos de la alarma extraídos
            if (_lastAlarmData != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Datos extraídos por IA:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDataRow('📍 Ubicación', _lastAlarmData!.location),
                    _buildDataRow('🏷️ Tipo', _lastAlarmData!.locationType),
                    _buildDataRow('📏 Rango', '${_lastAlarmData!.range.toInt()} metros'),
                    _buildDataRow('📝 Nombre', _lastAlarmData!.alarmName),
                    _buildDataRow('🎯 Confianza', '${(_lastAlarmData!.confidence * 100).toInt()}%'),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // Ejemplos de comandos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Ejemplos de comandos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('• "Ponme una alarma para cuando llegue a Madrid"'),
                const Text('• "Alarma para llegar al trabajo"'),
                const Text('• "Despiértame cuando esté cerca del centro comercial"'),
                const Text('• "Alerta para cuando llegue a casa"'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recognitionService.dispose();
    super.dispose();
  }
}
