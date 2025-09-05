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

import 'database_helper.dart';
import 'create_alarma_page.dart';
import 'edit_alarma.dart';

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
  runApp(const WakeMapApp());
}

class WakeMapApp extends StatelessWidget {
  const WakeMapApp({super.key});
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0A84FF);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Wake-Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 34,
            fontFamily: 'MiFuente1',
          ),
          bodyMedium: TextStyle(fontSize: 16),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: 'MiFuente2',
          ),
        ),
      ),
      home: const HomePage(title: 'Wake-Map'),
    );
  }
}

class WeatherWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const WeatherWidget({
    required this.latitude,
    required this.longitude,
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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.thermometer,
              size: 24,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperatura: ${_temperature?.toStringAsFixed(1) ?? '--'} °C',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Viento: ${_windspeed?.toStringAsFixed(1) ?? '--'} km/h',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  LocationData? _currentLocation, _lastLocation;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final List<Map<String, dynamic>> _alarmas = [];
  final Set<int> _pinnedAlarmIds = <int>{};

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
      } catch (_) {}
    }
  }

  Future<void> _savePinnedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pinned_alarm_ids', jsonEncode(_pinnedAlarmIds.toList()));
  }

  int _compareAlarmas(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aId = (a['id'] ?? -1) as int;
    final bId = (b['id'] ?? -1) as int;
    final ap = _pinnedAlarmIds.contains(aId) ? 1 : 0;
    final bp = _pinnedAlarmIds.contains(bId) ? 1 : 0;
    if (ap != bp) return bp - ap; // Pinned primero
    final ai = (a['activa'] ?? 0) as int;
    final bi = (b['activa'] ?? 0) as int;
    if (ai != bi) return bi - ai; // Activas después dentro de pinned/no pinned
    final an = (a['nombre'] ?? '').toString().toLowerCase();
    final bn = (b['nombre'] ?? '').toString().toLowerCase();
    return an.compareTo(bn);
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
    final alarmas = await DatabaseHelper.instance.getAlarmas();
    if (!mounted) return;
    final activa = alarmas.firstWhere(
      (a) => a['activa'] == 1,
      orElse: () => {},
    );
    // Crear una lista mutable para ordenar
    final alarmasList = List<Map<String, dynamic>>.from(alarmas);
    // Ordenar según reglas: pinned -> activa -> nombre
    alarmasList.sort(_compareAlarmas);
    setState(() {
      _alarmas.clear();
      _alarmas.addAll(alarmasList);
      _centered = false;
      _weatherKey = activa.isNotEmpty
          ? 'active_${activa['id']}'
          : _currentLocation != null
              ? 'current_${_currentLocation!.latitude}_${_currentLocation!.longitude}'
              : 'default';
    });
    _drawRoute();
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
    // 1) Actualizar en BD
    for (final a in _alarmas) {
      await DatabaseHelper.instance.updateAlarma({
        ...a,
        'activa': (activar && a['id'] == id) ? 1 : 0,
      });
    }

    // 2) Actualizar en memoria y animar movimiento visual
    final oldIndex = _alarmas.indexWhere((a) => a['id'] == id);
    if (oldIndex == -1) {
      // Fallback a recarga si no se encuentra
      if (mounted) _loadAlarmas();
      return;
    }

    // Si se activa, fijarla como "pinned" para que quede arriba incluso al desactivar
    if (activar) {
      _pinnedAlarmIds.add(id);
      _savePinnedAlarms();
    }

    // Reflejar cambios de activa en memoria
    for (var i = 0; i < _alarmas.length; i++) {
      _alarmas[i] = {
        ..._alarmas[i],
        'activa': (activar && _alarmas[i]['id'] == id) ? 1 : 0,
      };
    }

    // Calcular nuevo índice según regla: activa primero, luego por nombre ASC
    List<Map<String, dynamic>> targetOrder = List<Map<String, dynamic>>.from(_alarmas);
    targetOrder.sort(_compareAlarmas);
    final item = _alarmas.firstWhere((a) => a['id'] == id);
    final newIndex = targetOrder.indexWhere((a) => a['id'] == id);

    if (newIndex == -1 || newIndex == oldIndex) {
      if (mounted) setState(() => _centered = false);
      // Redibujar ruta/clima sin animación si no hay movimiento
      _weatherKey = (item['activa'] == 1)
          ? 'active_${item['id']}'
          : (_currentLocation != null
              ? 'current_${_currentLocation!.latitude}_${_currentLocation!.longitude}'
              : 'default');
      _drawRoute();
      return;
    }

    // Animar: quitar del índice viejo e insertar en el nuevo
    final removedItem = _alarmas.removeAt(oldIndex);
    _listKey.currentState?.removeItem(
      oldIndex,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildAlarmaCard(removedItem, Theme.of(context)),
      ),
      duration: const Duration(milliseconds: 120),
    );

    // Insertar tras pequeña espera para que la animación de salida termine
    Future.delayed(const Duration(milliseconds: 160), () {
      _alarmas.insert(newIndex, removedItem);
      _listKey.currentState?.insertItem(
        newIndex,
        duration: const Duration(milliseconds: 180),
      );
      if (mounted) {
        setState(() {
          _centered = false;
          _weatherKey = (removedItem['activa'] == 1)
              ? 'active_${removedItem['id']}'
              : (_currentLocation != null
                  ? 'current_${_currentLocation!.latitude}_${_currentLocation!.longitude}'
                  : 'default');
        });
      }
      _drawRoute();
    });
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

  Widget _buildAlarmaCard(Map<String, dynamic> alarma, ThemeData theme) {
    final isActive = alarma['activa'] == 1;
    final isPinned = _pinnedAlarmIds.contains(alarma['id']);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive 
            ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.black12,
            blurRadius: isActive ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    CupertinoIcons.location_solid,
                    color: isActive ? theme.colorScheme.primary : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alarma['nombre'] ?? 'Sin nombre',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPinned) 
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'FIJA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isActive ? CupertinoIcons.bell_solid : CupertinoIcons.bell,
                              key: ValueKey(isActive),
                              size: 20,
                              color: isActive ? theme.colorScheme.primary : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dirección: ${alarma['ubicacion'] ?? 'Desconocida'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rango: ${alarma['rango'] ?? '-'} m',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedScale(
                  scale: isActive ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Switch(
                    activeColor: theme.colorScheme.primary,
                    value: isActive,
                    onChanged: (val) => _toggleAlarmaActiva(alarma['id'], val),
                  ),
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
      appBar: AppBar(
        title: Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedSwitcher(
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
                : Column(
                    children: [
                      const SizedBox(height: 12),
                      WeatherWidget(
                        key: ValueKey(_weatherKey),
                        latitude: _getWeatherLocation().latitude,
                        longitude: _getWeatherLocation().longitude,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              height: 260,
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
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _alarmas.isEmpty
                            ? _buildEmptyState(theme)
                            : AnimatedList(
                                key: _listKey,
                                initialItemCount: _alarmas.length,
                                padding: const EdgeInsets.only(bottom: 20),
                                itemBuilder: (context, index, animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: SizeTransition(
                                      sizeFactor: animation,
                                      child: _buildAlarmaCard(_alarmas[index], theme),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: _currentLocation != null
          ? AnimatedScale(
              scale: _currentLocation != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton(
                backgroundColor: theme.colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  size: 24,
                  color: Colors.white,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateAlarmaPage()),
                  );
                  if (result == true) {
                    await _loadAlarmas();
                  }
                },
              ),
            )
          : null,
    );
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
              'No hay alarmas guardadas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para crear tu primera alarma',
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