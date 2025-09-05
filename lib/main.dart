import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'database_helper.dart';
import 'create_alarma_page.dart';
import 'edit_alarma.dart';
import 'env.dart';

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
  await dotenv.load(fileName: ".env");
  runApp(const WakeMapApp());
}

class WakeMapApp extends StatelessWidget {
  const WakeMapApp({super.key});
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    const seedColor = Color.fromRGBO(170, 161, 116, 1);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Wake-Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 40,
            fontFamily: 'MiFuente1',
          ),
          bodyMedium: TextStyle(fontSize: 16),
          titleMedium: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
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

  Future<void> _fetchWeather() async {
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=${widget.latitude}&longitude=${widget.longitude}&current_weather=true';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentWeather = data['current_weather'];
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
            _error = 'Error del servidor del clima (código: ${response.statusCode})';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo conectar al servicio del clima';
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
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.thermostat, size: 40, color: Colors.orange),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temperatura: ${_temperature?.toStringAsFixed(1) ?? '--'} °C',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Viento: ${_windspeed?.toStringAsFixed(1) ?? '--'} km/h',
                style: const TextStyle(fontSize: 14),
              ),
            ],
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
    if (await _requestPermission()) {
      _currentLocation = await _location.getLocation();
      _loading = false;
      setState(() {});
      _location.onLocationChanged.listen(_onLocationChanged);
      await ph.Permission.notification.request();
    }
    _loadAlarmas();
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
    if (_lastLocation?.latitude != loc.latitude ||
        _lastLocation?.longitude != loc.longitude) {
      _lastLocation = loc;
      setState(() => _currentLocation = loc);
    }
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

    final dist = Geolocator.distanceBetween(
      loc.latitude!,
      loc.longitude!,
      activa['latitud'],
      activa['longitud'],
    );
    final rango = double.tryParse('${activa['rango']}') ?? 100;

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
    setState(() {
      _alarmas.clear();
      _alarmas.addAll(alarmas);
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
    for (final a in _alarmas) {
      await DatabaseHelper.instance.updateAlarma({
        ...a,
        'activa': (activar && a['id'] == id) ? 1 : 0,
      });
    }
    if (mounted) {
      setState(() => _centered = false);
      _loadAlarmas();
    }
  }

  Future<void> _drawRoute() async {
    final activa = _alarmas.firstWhere(
      (a) => a['activa'] == 1,
      orElse: () => {},
    );
    if (activa.isEmpty || _currentLocation == null) {
      setState(() {
        _polylines.clear();
        _markers.clear();
        _circles.clear();
        _lastRoute.clear();
        _lastOrig = null;
        _lastDest = null;
        _centered = false;
      });
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

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$oLat,$oLng&destination=$lat,$lng&key=$googleMapsApiKey';
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if ((data['routes'] as List).isEmpty) return;

    final encoded = data['routes'][0]['overview_polyline']['points'];
    List<PointLatLng> decodedPoints = PolylinePoints().decodePolyline(encoded);
    final routePoints = decodedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
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
              title: const Text('Eliminar Alarma'),
              content: const Text('¿Deseas eliminar esta alarma?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context,  true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );
          if (confirm == true) await _deleteAlarma(alarma['id']);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.location_on, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarma['nombre'] ?? 'Sin nombre',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text('Dirección: ${alarma['ubicacion'] ?? 'Desconocida'}'),
                    Text('Rango: ${alarma['rango'] ?? '-'} m'),
                  ],
                ),
              ),
              Switch(
                activeColor: theme.colorScheme.primary,
                value: alarma['activa'] == 1,
                onChanged: (val) => _toggleAlarmaActiva(alarma['id'], val),
              ),
            ],
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
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: theme.colorScheme.primary,
        centerTitle: true,
        elevation: 3,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
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
                      SizedBox(
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
                      const SizedBox(height: 14),
                      Expanded(
                        child: _alarmas.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay alarmas guardadas',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              )
                            : ListView.builder(
                                itemCount: _alarmas.length,
                                padding: const EdgeInsets.only(bottom: 20),
                                itemBuilder: (_, i) =>
                                    _buildAlarmaCard(_alarmas[i], theme),
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: _currentLocation != null
          ? FloatingActionButton(
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAlarmaPage()),
                );
                await _loadAlarmas();
              },
            )
          : null,
    );
  }

  Widget _buildPermissionRetry(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No se han concedido permisos de ubicación',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initialize,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar permisos'),
            ),
          ],
        ),
      ),
    );
  }
}