import 'package:flutter/material.dart';
import 'voice_alarm_service.dart';
import 'voice_alarm_interface.dart';
import 'package:tfg_definitivo2/widgets/glass_navbar.dart';

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
      // Verificar primero si la API key está configurada
      final isConfigured = await _voiceService.isApiKeyConfigured;
      if (!isConfigured) {
        setState(() {
          _testResult = '''❌ Clave de API no configurada

Para configurar tu clave de API de Gemini:
1. Obtén una nueva clave en: https://makersuite.google.com/app/apikey
2. Ve a Ajustes > Configuración de API en la app
3. Ingresa tu clave de API

Nota: La clave anterior fue reportada como filtrada y ya no funciona.''';
          _isLoading = false;
        });
        return;
      }

      final success = await _voiceService.testConnection();
      
      setState(() {
        _testResult = success 
          ? '✅ Conexión exitosa con Gemini!\n\nLa API está funcionando correctamente.' 
          : '❌ Error conectando con Gemini\n\nVerifica que tu clave de API sea válida y tenga los permisos necesarios.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Error: $e\n\nVerifica la configuración de tu clave de API.';
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
      // Verificar primero si la API key está configurada
      final isConfigured = await _voiceService.isApiKeyConfigured;
      if (!isConfigured) {
        setState(() {
          _testResult = '''❌ Clave de API no configurada

Para configurar tu clave de API de Gemini:
1. Obtén una nueva clave en: https://makersuite.google.com/app/apikey
2. Ve a Ajustes > Configuración de API en la app
3. Ingresa tu clave de API

Nota: La clave anterior fue reportada como filtrada y ya no funciona.''';
          _isLoading = false;
        });
        return;
      }

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
          _testResult = '''❌ No se pudo procesar el comando

Posibles causas:
- La clave de API no es válida
- La clave fue reportada como filtrada
- Error de conexión con la API

Verifica los logs para más detalles.''';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '''❌ Error procesando comando: $e

Verifica que tu clave de API esté correctamente configurada y sea válida.''';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Permite que el contenido se extienda detrás del navbar
      appBar: AppBar(
        title: const Text('Test de Comandos por Voz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Contenido que se extiende completamente
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Padding inferior para el navbar
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
                                  fontFamily: 'SF Pro Display',
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
          // Navbar posicionado en la parte inferior
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
