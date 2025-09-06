import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'database_helper.dart';
import 'create_alarma_page.dart';
import 'edit_alarma.dart';
import 'settings_page.dart';
import 'theme_manager.dart';
import 'theme_provider.dart';
import 'l10n/app_localizations.dart';

class AlarmHelper {
  static const MethodChannel _channel = MethodChannel(
    'com.example.tfg_definitivo2/alarm',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.example.tfg_definitivo2/alarm/events',
  );

  static Stream<String> get alarmEvents =>
      _eventChannel.receiveBroadcastStream().cast<String>();

  static Future<void> startAlarmActivity() async {
    try {
      await _channel.invokeMethod('startAlarm');
    } on PlatformException catch (e) {
      debugPrint('Error al iniciar alarma nativa: ${e.message}');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialize();
  runApp(const WakeMapApp());
}

class WakeMapApp extends StatefulWidget {
  const WakeMapApp({super.key});
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<WakeMapApp> createState() => _WakeMapAppState();
}

class _WakeMapAppState extends State<WakeMapApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await _themeProvider.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      // Escuchar cambios en el tema del sistema
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSystemUI();
      });
    }
  }

  void _updateSystemUI() {
    if (mounted) {
      ThemeManager.updateSystemUIOverlayStyle(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => _themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: WakeMapApp.navigatorKey,
            title: 'Wake-Map',
            debugShowCheckedModeBanner: false,
            theme: ThemeManager.getLightTheme(),
            darkTheme: ThemeManager.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: themeProvider.locale,
            home: const HomePage(title: 'Wake-Map'),
            builder: (context, child) {
              // Actualizar UI del sistema cuando cambie el tema
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ThemeManager.updateSystemUIOverlayStyle(context);
              });
              return child!;
            },
          );
        },
      ),
    );
  }
}

class WeatherWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const WeatherWidget({
    required this.latitude,
    required this.longitude,
    this.locationName,
    Key? key,
  }) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  double? _temperature;
  double? _windspeed;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    // Generar clave de caché basada en coordenadas
    final cacheKey = 'weather_${widget.latitude.toStringAsFixed(2)}_${widget.longitude.toStringAsFixed(2)}';
    
    // Intentar cargar desde caché primero
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt('${cacheKey}_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Si hay datos en caché y tienen menos de 10 minutos, usarlos
    if (cachedData != null && (now - cachedTime) < 600000) {
      try {
        final data = jsonDecode(cachedData);
        if (mounted) {
          setState(() {
            _temperature = data['temperature']?.toDouble();
            _windspeed = data['windspeed']?.toDouble();
            _loading = false;
          });
        }
        return;
      } catch (e) {
        // Si hay error con el caché, continuar con la petición
      }
    }

    final url =
        'http://api.open-meteo.com/v1/forecast?latitude=${widget.latitude}&longitude=${widget.longitude}&current_weather=true';

    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return; // Verificar si el widget sigue montado
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentWeather = data['current_weather'];
        
        // Guardar en caché
        final weatherData = {
          'temperature': currentWeather['temperature'],
          'windspeed': currentWeather['windspeed'],
        };
        await prefs.setString(cacheKey, jsonEncode(weatherData));
        await prefs.setInt('${cacheKey}_time', now);
        
        if (mounted) {
          setState(() {
            _temperature = (currentWeather['temperature'] as num?)?.toDouble();
            _windspeed = (currentWeather['windspeed'] as num?)?.toDouble();
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Error al obtener clima';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error de conexión';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)]
              : [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '+${_temperature?.toStringAsFixed(0) ?? '--'}°C',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.locationName != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.locationName!,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,  
                            color: Colors.white.withOpacity(0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(  
                  children: [
                    Icon(
                      CupertinoIcons.cloud_sun,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Low cloudiness',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              CupertinoIcons.cloud_sun_fill,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Location _location = Location();
  final AudioPlayer _audioPlayer = AudioPlayer();

  GoogleMapController? _mapController;
  LocationData? _currentLocation, _lastLocation;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final List<Map<String, dynamic>> _alarmas = [];
  final List<int> _pinnedAlarmIds = <int>[];
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();
  int? _lastActivatedAlarmId; // Para detectar qué alarma se activó recientemente

  Map<String, dynamic>? _lastDeletedAlarma;
  List<LatLng> _lastRoute = [];
  LatLng? _lastOrig, _lastDest;
  String? _weatherKey;

  bool _loading = true, _notified = false, _centered = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    AlarmHelper.alarmEvents.listen((event) {
      if (event == 'alarm_stopped') _onAlarmStopped();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadPinnedAlarms();
    if (await _requestPermission()) {
      _currentLocation = await _location.getLocation();
      _loading = false;
      setState(() {});
      _location.onLocationChanged.listen(_onLocationChanged);
      await ph.Permission.notification.request();
    }
    _loadAlarmas();
  }

  Future<void> _loadPinnedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pinned_alarm_ids');
    _pinnedAlarmIds.clear();
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<int>();
        _pinnedAlarmIds.addAll(list);
        print('Pinned alarms cargadas: $_pinnedAlarmIds');
      } catch (e) {
        print('Error cargando pinned alarms: $e');
      }
    } else {
      print('No hay pinned alarms guardadas');
    }
  }

  Future<void> _savePinnedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_pinnedAlarmIds.toList());
    await prefs.setString('pinned_alarm_ids', jsonString);
    print('Pinned alarms guardadas: $jsonString');
  }

  Future<void> _unpinAlarma(int id) async {
    _pinnedAlarmIds.remove(id);
    await _savePinnedAlarms();
    await _loadAlarmas();
  }

  int _compareAlarmas(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aId = (a['id'] ?? -1) as int;
    final bId = (b['id'] ?? -1) as int;
    final aIsPinned = _pinnedAlarmIds.contains(aId);
    final bIsPinned = _pinnedAlarmIds.contains(bId);
    
    print('Comparando: ${a['nombre']} (ID: $aId, pinned: $aIsPinned) vs ${b['nombre']} (ID: $bId, pinned: $bIsPinned)');
    
    // 1. PRIORIDAD MÁXIMA: Alarmas pinned (usadas recientemente) SIEMPRE primero
    if (aIsPinned && !bIsPinned) {
      print('  -> ${a['nombre']} va primero (pinned)');
      return -1; // a va antes que b
    }
    if (!aIsPinned && bIsPinned) {
      print('  -> ${b['nombre']} va primero (pinned)');
      return 1; // b va antes que a
    }
    
    // 2. Si ambas son pinned, ordenar por posición en la lista (más reciente primero)
    if (aIsPinned && bIsPinned) {
      final aIndex = _pinnedAlarmIds.indexOf(aId);
      final bIndex = _pinnedAlarmIds.indexOf(bId);
      final result = aIndex.compareTo(bIndex);
      print('  -> Orden por uso reciente: $aIndex vs $bIndex = $result');
      return result;
    }
    
    // 3. Si ninguna es pinned, ordenar por activa
    final aIsActive = (a['activa'] ?? 0) == 1;
    final bIsActive = (b['activa'] ?? 0) == 1;
    
    if (aIsActive && !bIsActive) {
      print('  -> ${a['nombre']} va primero (activa)');
      return -1;
    }
    if (!aIsActive && bIsActive) {
      print('  -> ${b['nombre']} va primero (activa)');
      return 1;
    }
    
    // 4. Finalmente, orden alfabético
    final aName = (a['nombre'] ?? '').toString().toLowerCase();
    final bName = (b['nombre'] ?? '').toString().toLowerCase();
    final result = aName.compareTo(bName);
    print('  -> Orden alfabético: $result');
    return result;
  }

  Future<bool> _requestPermission() async {
    final status = await ph.Permission.location.request();
    if (status.isGranted) return true;

    final dialogResult = await _showPermissionDialog(
      title: 'Permisos de ubicación requeridos',
      content:
          status.isPermanentlyDenied
              ? 'Debes habilitarlos desde configuración.'
              : 'Por favor, acepta para continuar.',
      isPermanent: status.isPermanentlyDenied,
    );
    return dialogResult ? await _requestPermission() : false;
  }

  Future<bool> _showPermissionDialog({
    required String title,
    required String content,
    required bool isPermanent,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(isPermanent ? 'Configuración' : 'Reintentar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (isPermanent && result == true) await ph.openAppSettings();
    return result ?? false;
  }

  void _onLocationChanged(LocationData loc) {
    // Solo actualizar si la ubicación cambió significativamente (evitar micro-movimientos)
    const double threshold = 0.0001; // ~11 metros
    final latChanged = (_lastLocation?.latitude ?? 0) - (loc.latitude ?? 0);
    final lngChanged = (_lastLocation?.longitude ?? 0) - (loc.longitude ?? 0);
    
    if (latChanged.abs() > threshold || lngChanged.abs() > threshold) {
      _lastLocation = loc;
      setState(() => _currentLocation = loc);
      
      if (_mapController != null && !_centered && _lastRoute.isEmpty) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(loc.latitude!, loc.longitude!),
              zoom: 14,
            ),
          ),
        );
      }
      _drawRoute();
      _checkProximity(loc);
    }
  }

  void _onAlarmStopped() async {
    final activa = _alarmas.firstWhere(
      (a) => a['activa'] == 1,
      orElse: () => {},
    );
    if (activa.isNotEmpty) await _toggleAlarmaActiva(activa['id'], false);
    if (mounted) setState(() => _notified = false);
  }

  void _checkProximity(LocationData loc) async {
    final activa = _alarmas.firstWhere(
      (a) => a['activa'] == 1,
      orElse: () => {},
    );
    if (activa.isEmpty) {
      if (_notified) await _stopAlarm();
      return;
    }

    // Calcular distancia solo si es necesario
    final rango = double.tryParse('${activa['rango']}') ?? 100;
    final dist = Geolocator.distanceBetween(
      loc.latitude!,
      loc.longitude!,
      activa['latitud'],
      activa['longitud'],
    );

    // Solo cambiar estado si hay cambio real
    if (dist <= rango && !_notified) {
      _notified = true;
      await AlarmHelper.startAlarmActivity();
    } else if (dist > rango && _notified) {
      _notified = false;
      await _stopAlarm();
    }
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.pause();
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.release);
  }

  Future<void> _loadAlarmas() async {
    print('=== CARGANDO ALARMAS ===');
    
    // Asegurarse de que las alarmas pinned estén cargadas
    await _loadPinnedAlarms();
    
    final alarmas = await DatabaseHelper.instance.getAlarmas();
    if (!mounted) return;
    
    print('Alarmas cargadas desde BD: ${alarmas.length}');
    print('Pinned IDs: $_pinnedAlarmIds');
    
    // Debug: mostrar estado inicial de cada alarma
    for (var alarma in alarmas) {
      final isPinned = _pinnedAlarmIds.contains(alarma['id']);
      final isActive = (alarma['activa'] ?? 0) == 1;
      print('  ${alarma['nombre']} (ID: ${alarma['id']}) - Pinned: $isPinned, Activa: $isActive');
    }
    
    final activa = alarmas.firstWhere(
      (a) => a['activa'] == 1,
      orElse: () => {},
    );
    
    // Crear una lista mutable para ordenar
    final alarmasList = List<Map<String, dynamic>>.from(alarmas);
    
    print('Ordenando alarmas...');
    // Ordenar según reglas: pinned -> activa -> nombre
    alarmasList.sort(_compareAlarmas);
    
    // Debug: imprimir alarmas después del ordenamiento
    print('=== ORDEN FINAL ===');
    for (var i = 0; i < alarmasList.length; i++) {
      final alarma = alarmasList[i];
      final isPinned = _pinnedAlarmIds.contains(alarma['id']);
      final isActive = (alarma['activa'] ?? 0) == 1;
      print('$i: ${alarma['nombre']} (ID: ${alarma['id']}) - Pinned: $isPinned, Activa: $isActive');
    }
    
    // Animar los cambios en la lista
    _animateListChanges(alarmasList);
    
    setState(() {
      _centered = false;
      _weatherKey = activa.isNotEmpty
          ? 'active_${activa['id']}'
          : _currentLocation != null
              ? 'current_${_currentLocation!.latitude}_${_currentLocation!.longitude}'
              : 'default';
    });
    _drawRoute();
  }

  void _animateListChanges(List<Map<String, dynamic>> newAlarmasList) {
    // Crear mapas para comparar posiciones
    final Map<int, int> oldPositions = {};
    final Map<int, int> newPositions = {};
    
    // Mapear posiciones antiguas
    for (int i = 0; i < _alarmas.length; i++) {
      oldPositions[_alarmas[i]['id']] = i;
    }
    
    // Mapear posiciones nuevas
    for (int i = 0; i < newAlarmasList.length; i++) {
      newPositions[newAlarmasList[i]['id']] = i;
    }
    
    // Encontrar alarmas que han cambiado de posición
    final List<int> movedAlarmIds = [];
    for (final alarma in newAlarmasList) {
      final id = alarma['id'];
      if (oldPositions.containsKey(id) && 
          oldPositions[id] != newPositions[id]) {
        movedAlarmIds.add(id);
      }
    }
    
    // Actualizar la lista
    _alarmas.clear();
    _alarmas.addAll(newAlarmasList);
    
    if (movedAlarmIds.isNotEmpty) {
      print('Alarmas que se movieron: $movedAlarmIds');
    }
  }

  Widget _buildAnimatedAlarmaCard(Map<String, dynamic> alarma, Animation<double> animation, ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: _buildAlarmaCard(alarma, theme),
      ),
    );
  }

  Future<void> _deleteAlarma(int id) async {
    _lastDeletedAlarma = _alarmas.firstWhere((a) => a['id'] == id);
    await DatabaseHelper.instance.deleteAlarma(id);
    await _loadAlarmas();
    _showUndoSnackBar();
  }

  void _showUndoSnackBar() {
    ScaffoldMessenger.of(WakeMapApp.navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: const Text('Alarma eliminada'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DESHACER',
          onPressed: () async {
            if (_lastDeletedAlarma != null) {
              await DatabaseHelper.instance.insertAlarma(_lastDeletedAlarma!);
              await _loadAlarmas();
              _lastDeletedAlarma = null;
            }
          },
        ),
      ),
    );
  }

  Future<void> _toggleAlarmaActiva(int id, bool activar) async {
    print('=== TOGGLE ALARMA ===');
    print('ID: $id, Activar: $activar');
    print('Pinned IDs ANTES: $_pinnedAlarmIds');
    
    // 1) Actualizar todas las alarmas en BD
    for (final alarma in _alarmas) {
      if (activar && alarma['id'] == id) {
        // Activar solo la alarma seleccionada
        await DatabaseHelper.instance.updateAlarma({
          ...alarma,
          'activa': 1,
        });
        print('Activada: ${alarma['nombre']}');
      } else {
        // Desactivar todas las demás alarmas
        await DatabaseHelper.instance.updateAlarma({
          ...alarma,
          'activa': 0,
        });
        if (alarma['activa'] == 1) {
          print('Desactivada: ${alarma['nombre']}');
        }
      }
    }
    print('Base de datos actualizada');

    // Si se activa, fijarla como "pinned" para que quede arriba incluso al desactivar
    if (activar) {
      // Remover si ya existe para evitar duplicados
      _pinnedAlarmIds.remove(id);
      // Añadir al principio de la lista (posición 0) para que sea la más reciente
      _pinnedAlarmIds.insert(0, id);
      // Guardar el ID de la alarma que se activó para animación especial
      _lastActivatedAlarmId = id;
      await _savePinnedAlarms();
      print('Añadido a pinned (posición 0): $id');
    } else {
      // Si se desactiva, limpiar el ID de activación
      _lastActivatedAlarmId = null;
    }

    print('Pinned IDs DESPUÉS: $_pinnedAlarmIds');
    
    // Recargar alarmas para reflejar cambios
    print('Recargando alarmas...');
    await _loadAlarmas();
    print('=== FIN TOGGLE ===');
  }

  Future<void> _drawRoute() async {
    final activa = _alarmas.firstWhere(
      (a) => a['activa'] == 1,
      orElse: () => {},
    );
    if (activa.isEmpty || _currentLocation == null) {
      if (_polylines.isNotEmpty || _markers.isNotEmpty || _circles.isNotEmpty) {
        setState(() {
          _polylines.clear();
          _markers.clear();
          _circles.clear();
          _lastRoute.clear();
          _lastOrig = null;
          _lastDest = null;
          _centered = false;
        });
      }
      // Recentrar mapa al estado normal (ubicación actual con zoom por defecto)
      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
              zoom: 14,
            ),
          ),
        );
      }
      return;
    }

    final oLat = _currentLocation!.latitude!;
    final oLng = _currentLocation!.longitude!;
    final lat = activa['latitud'], lng = activa['longitud'];
    final rango = double.tryParse('${activa['rango']}') ?? 100.0;

    final originChanged =
        _lastOrig?.latitude != oLat || _lastOrig?.longitude != oLng;
    final destChanged =
        _lastDest?.latitude != lat || _lastDest?.longitude != lng;

    if (!originChanged && !destChanged) return;

    // Generar clave de caché para la ruta
    final routeCacheKey = 'route_${oLat.toStringAsFixed(3)}_${oLng.toStringAsFixed(3)}_${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
    final prefs = await SharedPreferences.getInstance();
    final cachedRoute = prefs.getString(routeCacheKey);
    final cachedRouteTime = prefs.getInt('${routeCacheKey}_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    List<LatLng> routePoints;
    
    // Si hay ruta en caché y tiene menos de 1 hora, usarla
    if (cachedRoute != null && (now - cachedRouteTime) < 3600000) {
      try {
        final cachedPoints = (jsonDecode(cachedRoute) as List)
            .map((point) => LatLng(point['lat'], point['lng']))
            .toList();
        routePoints = cachedPoints;
      } catch (e) {
        // Si hay error con el caché, continuar con la petición
        routePoints = await _fetchRouteFromAPI(oLat, oLng, lat, lng, routeCacheKey, prefs, now);
      }
    } else {
      routePoints = await _fetchRouteFromAPI(oLat, oLng, lat, lng, routeCacheKey, prefs, now);
    }

    if (routePoints.isEmpty) return;

    setState(() {
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            width: 5,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('dest'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: activa['nombre']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRose,
            ),
          ),
        );
      _circles
        ..clear()
        ..add(
          Circle(
            circleId: const CircleId('rango_activacion'),
            center: LatLng(lat, lng),
            radius: rango,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blueAccent,
            strokeWidth: 2,
          ),
        );
      _lastRoute = routePoints;
      _lastDest = LatLng(lat, lng);
      _lastOrig = LatLng(oLat, oLng);
      _centered = true;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(_bounds(routePoints), 50),
    );
  }

  Future<List<LatLng>> _fetchRouteFromAPI(double oLat, double oLng, double lat, double lng, String cacheKey, SharedPreferences prefs, int now) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$oLat,$oLng&destination=$lat,$lng&key=AIzaSyB5Nc_EBy8tO9Wyh0K0B96RDkN9d-MET_4';
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if ((data['routes'] as List).isEmpty) return [];

    final encoded = data['routes'][0]['overview_polyline']['points'];
    final routePoints = _decodePolyline(encoded);
    
    // Guardar en caché
    final routeData = routePoints.map((point) => {
      'lat': point.latitude,
      'lng': point.longitude,
    }).toList();
    await prefs.setString(cacheKey, jsonEncode(routeData));
    await prefs.setInt('${cacheKey}_time', now);
    
    return routePoints;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  LatLngBounds _bounds(List<LatLng> pts) {
    double minLat = double.infinity, minLng = double.infinity;
    double maxLat = -double.infinity, maxLng = -double.infinity;

    for (final p in pts) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  LatLng _getWeatherLocation() {
    final activa = _alarmas.firstWhere(
      (a) => a['activa'] == 1,
      orElse: () => {},
    );
    if (activa.isNotEmpty) {
      return LatLng(activa['latitud'], activa['longitud']);
    }
    if (_currentLocation != null) {
      return LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    }
    return const LatLng(40.416775, -3.703790); // Madrid como ubicación predeterminada
  }

  Future<String?> _getLocationName(double latitude, double longitude) async {
    // Generar clave de caché para el nombre de ubicación
    final cacheKey = 'location_name_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt('${cacheKey}_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Si hay nombre en caché y tiene menos de 1 hora, usarlo
    if (cachedName != null && (now - cachedTime) < 3600000) {
      return cachedName;
    }

    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=AIzaSyB5Nc_EBy8tO9Wyh0K0B96RDkN9d-MET_4&language=es';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          final result = data['results'][0];
          String locationName = result['formatted_address'];
          
          // Simplificar el nombre si es muy largo
          if (locationName.length > 30) {
            final components = locationName.split(',');
            if (components.length >= 2) {
              locationName = '${components[0].trim()}, ${components[1].trim()}';
            }
          }
          
          // Guardar en caché
          await prefs.setString(cacheKey, locationName);
          await prefs.setInt('${cacheKey}_time', now);
          
          return locationName;
        }
      }
    } catch (e) {
      print('Error obteniendo nombre de ubicación: $e');
    }
    
    return null;
  }

  Future<Map<String, dynamic>> _getWeatherLocationData() async {
    final activa = _alarmas.firstWhere(
      (a) => a['activa'] == 1,
      orElse: () => {},
    );
    
    if (activa.isNotEmpty) {
      final locationName = await _getLocationName(activa['latitud'], activa['longitud']);
      return {
        'latitude': activa['latitud'],
        'longitude': activa['longitud'],
        'locationName': locationName ?? activa['nombre'] ?? 'Ubicación de alarma',
      };
    }
    
    if (_currentLocation != null) {
      final locationName = await _getLocationName(_currentLocation!.latitude!, _currentLocation!.longitude!);
      return {
        'latitude': _currentLocation!.latitude!,
        'longitude': _currentLocation!.longitude!,
        'locationName': locationName ?? AppLocalizations.of(context).myLocation,
      };
    }
    
    return {
      'latitude': 40.416775,
      'longitude': -3.703790,
      'locationName': 'Madrid, España',
    };
  }

  String? _getMapStyle() {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return '''
        [
          {
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#212121"
              }
            ]
          },
          {
            "elementType": "labels.icon",
            "stylers": [
              {
                "visibility": "off"
              }
            ]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#757575"
              }
            ]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [
              {
                "color": "#212121"
              }
            ]
          },
          {
            "featureType": "administrative",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#757575"
              }
            ]
          },
          {
            "featureType": "administrative.country",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#9e9e9e"
              }
            ]
          },
          {
            "featureType": "administrative.land_parcel",
            "stylers": [
              {
                "visibility": "off"
              }
            ]
          },
          {
            "featureType": "administrative.locality",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#bdbdbd"
              }
            ]
          },
          {
            "featureType": "poi",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#757575"
              }
            ]
          },
          {
            "featureType": "poi.park",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#181818"
              }
            ]
          },
          {
            "featureType": "poi.park",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#616161"
              }
            ]
          },
          {
            "featureType": "poi.park",
            "elementType": "labels.text.stroke",
            "stylers": [
              {
                "color": "#1b1b1b"
              }
            ]
          },
          {
            "featureType": "road",
            "elementType": "geometry.fill",
            "stylers": [
              {
                "color": "#2c2c2c"
              }
            ]
          },
          {
            "featureType": "road",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#8a8a8a"
              }
            ]
          },
          {
            "featureType": "road.arterial",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#373737"
              }
            ]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#3c3c3c"
              }
            ]
          },
          {
            "featureType": "road.highway.controlled_access",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#4e4e4e"
              }
            ]
          },
          {
            "featureType": "road.local",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#616161"
              }
            ]
          },
          {
            "featureType": "transit",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#757575"
              }
            ]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#000000"
              }
            ]
          },
          {
            "featureType": "water",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#3d3d3d"
              }
            ]
          }
        ]
      ''';
    }
    return null; // Usar estilo por defecto para modo claro
  }

  Widget _buildAlarmaCard(Map<String, dynamic> alarma, ThemeData theme, {Key? key}) {
    final isActive = alarma['activa'] == 1;
    final isPinned = _pinnedAlarmIds.contains(alarma['id']);
    final isRecentlyActivated = _lastActivatedAlarmId == alarma['id'];
    
    return AnimatedContainer(
      key: key,
      duration: Duration(milliseconds: isRecentlyActivated ? 800 : 300),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: isRecentlyActivated 
            ? Border.all(
                color: theme.colorScheme.primary.withOpacity(0.8),
                width: 2,
              )
            : null,
        boxShadow: isRecentlyActivated
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : theme.brightness == Brightness.dark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditAlarmaPage(
                  alarma: alarma,
                  onDelete: (alarmaEliminada) async {
                    _lastDeletedAlarma = alarmaEliminada;
                    await _loadAlarmas();
                    _showUndoSnackBar();
                  },
                ),
              ),
            );
            if (updated == true) await _loadAlarmas();
          },
          onLongPress: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Eliminar Alarma'),
                content: const Text('¿Deseas eliminar esta alarma?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
            if (confirm == true) await _deleteAlarma(alarma['id']);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.location_solid,
                  color: theme.textTheme.bodySmall?.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarma['nombre'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context).address}: ${alarma['ubicacion'] ?? AppLocalizations.of(context).unknown}',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppLocalizations.of(context).range}: ${alarma['rango'] ?? '-'} m',
                        style: TextStyle(
                          color: theme.textTheme.labelMedium?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  activeColor: theme.colorScheme.primary,
                  value: isActive,
                  onChanged: (val) => _toggleAlarmaActiva(alarma['id'], val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header personalizado
            _buildCustomHeader(theme),
            // Contenido principal
            Expanded(
              child: _buildMainContent(theme),
            ),
            // Barra de navegación inferior
            _buildBottomNavigation(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'WakeMap',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                  final currentTheme = themeProvider.currentThemeString;
                  final newTheme = currentTheme == 'dark' ? 'light' : 'dark';
                  await themeProvider.setTheme(newTheme);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    theme.brightness == Brightness.dark 
                        ? CupertinoIcons.sun_max
                        : CupertinoIcons.moon,
                    color: theme.brightness == Brightness.dark 
                        ? Colors.white
                        : Colors.black,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark 
                      ? Colors.pink.withOpacity(0.2)
                      : Colors.pink[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: theme.brightness == Brightness.dark 
                      ? Colors.pink[300]
                      : Colors.pink[600],
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 20,
              ),
            )
          : _currentLocation == null
              ? _buildPermissionRetry(theme)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      FutureBuilder<Map<String, dynamic>>(
                        key: ValueKey(_weatherKey),
                        future: _getWeatherLocationData(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return WeatherWidget(
                              latitude: snapshot.data!['latitude'],
                              longitude: snapshot.data!['longitude'],
                              locationName: snapshot.data!['locationName'],
                            );
                          }
                          return WeatherWidget(
                            latitude: _getWeatherLocation().latitude,
                            longitude: _getWeatherLocation().longitude,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: theme.brightness == Brightness.dark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _currentLocation != null
                                  ? LatLng(
                                      _currentLocation!.latitude!,
                                      _currentLocation!.longitude!,
                                    )
                                  : const LatLng(0, 0),
                              zoom: 14,
                            ),
                            onMapCreated: (c) => _mapController = c,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            polylines: _polylines,
                            markers: _markers,
                            circles: _circles,
                            zoomControlsEnabled: false,
                            mapType: MapType.normal,
                            mapToolbarEnabled: false,
                            compassEnabled: true,
                            liteModeEnabled: false,
                            buildingsEnabled: true,
                            trafficEnabled: false,
                            indoorViewEnabled: false,
                            tiltGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            style: _getMapStyle(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _alarmas.isEmpty
                          ? _buildEmptyState(theme)
                          : Column(
                              children: _alarmas.asMap().entries.map((entry) {
                                final index = entry.key;
                                final alarma = entry.value;
                                final isRecentlyActivated = _lastActivatedAlarmId == alarma['id'];
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: isRecentlyActivated ? 2000 : 600),
                                    transitionBuilder: (child, animation) {
                                      if (isRecentlyActivated) {
                                        // Animación especial para la alarma recién activada
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 15.0), // Desde MUY FUERA de la pantalla
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.elasticOut, // Rebote muy dramático
                                          )),
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.5, // Más pequeño inicialmente
                                              end: 1.0,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.elasticOut,
                                            )),
                                            child: RotationTransition(
                                              turns: Tween<double>(
                                                begin: 0.2, // Más rotación
                                                end: 0.0,
                                              ).animate(CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.elasticOut,
                                              )),
                                              child: FadeTransition(
                                                opacity: Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ).animate(CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeIn,
                                                )),
                                                child: child,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Animación normal para otras alarmas
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.5),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      }
                                    },
                                    child: _buildAlarmaCard(alarma, theme, key: ValueKey('${alarma['id']}_$index')),
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: theme.brightness == Brightness.dark 
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  Colors.black,
                ],
                stops: const [0.0, 1.0],
              ),
        color: theme.brightness == Brightness.dark 
            ? const Color(0xFF1C1C1E)
            : null,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: theme.brightness == Brightness.dark
            ? Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(CupertinoIcons.home, AppLocalizations.of(context).home, true),
          _buildNavItem(CupertinoIcons.add, AppLocalizations.of(context).newTab, false),
          _buildNavItem(CupertinoIcons.settings, AppLocalizations.of(context).settings, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == AppLocalizations.of(context).newTab) {
          _showCreateAlarmaDialog();
        } else if (label == AppLocalizations.of(context).settings) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.white.withOpacity(0.2))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAlarmaDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAlarmaPage()),
    );
    if (result == true) {
      await _loadAlarmas();
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: AnimatedOpacity(
        opacity: 0.7,
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.bell,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).noAlarmsSaved,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).createFirstAlarm,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRetry(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.location_slash,
                size: 40,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Permisos de ubicación requeridos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Necesitamos acceso a tu ubicación para funcionar correctamente',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initialize,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Conceder permisos',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}