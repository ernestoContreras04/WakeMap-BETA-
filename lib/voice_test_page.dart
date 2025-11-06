import 'package:flutter/material.dart';
import 'voice_alarm_service.dart';
import 'voice_alarm_interface.dart';

class VoiceTestPage extends StatefulWidget {
  const VoiceTestPage({super.key});

  @override
  State<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends State<VoiceTestPage> {
  final VoiceAlarmService _voiceService = VoiceAlarmService();
  
  String _testResult = '';
  bool _isLoading = false;

  Future<void> _testGeminiConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Probando conexión con Gemini...';
    });

    try {
      final success = await _voiceService.testConnection();
      
      setState(() {
        _testResult = success 
          ? '✅ Conexión exitosa con Gemini!' 
          : '❌ Error conectando con Gemini';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testVoiceCommand(String command) async {
    setState(() {
      _isLoading = true;
      _testResult = 'Procesando comando: "$command"...';
    });

    try {
      final result = await _voiceService.processVoiceCommand(command);
      
      setState(() {
        if (result != null) {
          _testResult = '''
✅ Comando procesado exitosamente!

📍 Ubicación: ${result.location}
🏷️ Tipo: ${result.locationType}
📏 Rango: ${result.range.toInt()} metros
📝 Nombre: ${result.alarmName}
🎯 Confianza: ${(result.confidence * 100).toInt()}%
''';
        } else {
          _testResult = '❌ No se pudo procesar el comando';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Error procesando comando: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Comandos por Voz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Pruebas de IA',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGeminiConnection,
                      child: const Text('Probar Conexión Gemini'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎤 Comandos de Prueba (Escritos)',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTestButton(
                      'Ponme una alarma para cuando llegue a Madrid',
                      () => _testVoiceCommand('Ponme una alarma para cuando llegue a Madrid'),
                    ),
                    const SizedBox(height: 8),
                    
                    _buildTestButton(
                      'Alarma para llegar al trabajo',
                      () => _testVoiceCommand('Alarma para llegar al trabajo'),
                    ),
                    const SizedBox(height: 8),
                    
                    _buildTestButton(
                      'Despiértame cuando esté cerca del centro comercial',
                      () => _testVoiceCommand('Despiértame cuando esté cerca del centro comercial'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '🎙️ Comando por Voz Real',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const VoiceAlarmInterface(
                    onAlarmCreated: null, // Por ahora no creamos la alarma, solo mostramos los datos
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Resultados',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isLoading
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Procesando...'),
                            ],
                          )
                        : Text(
                            _testResult.isEmpty ? 'Presiona un botón para comenzar las pruebas' : _testResult,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
