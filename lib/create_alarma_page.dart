import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

import 'database_helper.dart';
import 'package:tfg_definitivo2/autocompletado.dart';

class CreateAlarmaPage extends StatefulWidget {
  const CreateAlarmaPage({super.key});

  @override
  State<CreateAlarmaPage> createState() => _CreateAlarmaPageState();
}

class _CreateAlarmaPageState extends State<CreateAlarmaPage> {
  final _nombreCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _rangoCtrl = TextEditingController();
  final _location = loc.Location();

  LatLng? _destino;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Marker? _radiusMarker;

  double _radius = 100.0;
  bool _loading = true;
  bool _updatingFromMap = false;
  bool _updatingFromText = false;

  static const _apiKey = 'AIzaSyB5Nc_EBy8tO9Wyh0K0B96RDkN9d-MET_4';

  @override
  void initState() {
    super.initState();
    _initLocation();

    _rangoCtrl.addListener(() {
      if (_updatingFromMap) return;
      final text = _rangoCtrl.text;
      final newRadius = double.tryParse(text);
      if (newRadius != null && _destino != null) {
        _updatingFromText = true;
        _radius = newRadius;
        _updateCircleAndMarker();
        _updatingFromText = false;
      }
    });
  }

  Future<void> _initLocation() async {
    if (await _location.requestPermission() != loc.PermissionStatus.granted) {
      _showMsg('Permiso de ubicación denegado');
      _setLoading(false);
      return;
    }
    final locData = await _location.getLocation();
    _setLoading(false);
    _updateDestino(LatLng(locData.latitude!, locData.longitude!));
  }

  void _setLoading(bool val) => mounted ? setState(() => _loading = val) : null;

  LatLngBounds _computeCircleBounds(LatLng center, double radius) {
    // Calculate bounds by finding points at opposite sides of the circle
    final north = _computeOffset(center, radius * 1.1, 0); // 10% padding
    final south = _computeOffset(center, radius * 1.1, 180);
    final east = _computeOffset(center, radius * 1.1, 90);
    final west = _computeOffset(center, radius * 1.1, 270);

    final minLat = min(south.latitude, min(north.latitude, min(east.latitude, west.latitude)));
    final maxLat = max(south.latitude, max(north.latitude, max(east.latitude, west.latitude)));
    final minLng = min(south.longitude, min(north.longitude, min(east.longitude, west.longitude)));
    final maxLng = max(south.longitude, max(north.longitude, max(east.longitude, west.longitude)));

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _updateDestino(LatLng latLng) {
    if (!mounted) return;
    setState(() {
      _destino = latLng;
      _markers.clear();

      _markers.add(Marker(
        markerId: const MarkerId('destino'),
        position: latLng,
        infoWindow: InfoWindow(title: _ubicacionCtrl.text),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      ));

      _circles = {
        Circle(
          circleId: const CircleId('rango_activacion'),
          center: latLng,
          radius: _radius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blueAccent,
          strokeWidth: 2,
        )
      };

      final offsetPos = _computeOffset(latLng, _radius, 90);
      _radiusMarker = Marker(
        markerId: const MarkerId('radius_marker'),
        position: offsetPos,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onDrag: (newPos) {
          _updatingFromMap = true;
          _updateRadius(newPos);
        },
      );
      _markers.add(_radiusMarker!);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_computeCircleBounds(latLng, _radius), 50),
      );
    });
  }

  void _updateRadius(LatLng newPos) {
    final distance = _calculateDistance(_destino!, newPos);
    setState(() {
      _radius = distance;
      _rangoCtrl.text = _radius.toInt().toString();

      _circles = {
        Circle(
          circleId: const CircleId('rango_activacion'),
          center: _destino!,
          radius: _radius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blueAccent,
          strokeWidth: 2,
        )
      };

      final newOffset = _computeOffset(_destino!, _radius, 90);
      _markers.removeWhere((m) => m.markerId.value == 'radius_marker');
      _radiusMarker = _radiusMarker!.copyWith(positionParam: newOffset);
      _markers.add(_radiusMarker!);

      _updatingFromMap = false;

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_computeCircleBounds(_destino!, _radius), 50),
      );
    });
  }

  void _updateCircleAndMarker() {
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('rango_activacion'),
          center: _destino!,
          radius: _radius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blueAccent,
          strokeWidth: 2,
        )
      };

      final newOffset = _computeOffset(_destino!, _radius, 90);
      _markers.removeWhere((m) => m.markerId.value == 'radius_marker');
      _radiusMarker = _radiusMarker!.copyWith(positionParam: newOffset);
      _markers.add(_radiusMarker!);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_computeCircleBounds(_destino!, _radius), 50),
      );
    });
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000;
    final lat1 = p1.latitude * pi / 180;
    final lat2 = p2.latitude * pi / 180;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLng = (p2.longitude - p1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  LatLng _computeOffset(LatLng origin, double distance, double bearing) {
    const earthRadius = 6378137.0;
    final bearingRad = bearing * pi / 180;
    final latRad = origin.latitude * pi / 180;
    final lngRad = origin.longitude * pi / 180;

    final newLat = asin(sin(latRad) * cos(distance / earthRadius) +
        cos(latRad) * sin(distance / earthRadius) * cos(bearingRad));
    final newLng = lngRad +
        atan2(
            sin(bearingRad) * sin(distance / earthRadius) * cos(latRad),
            cos(distance / earthRadius) - sin(latRad) * sin(newLat));

    return LatLng(newLat * 180 / pi, newLng * 180 / pi);
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveAlarma() async {
    final nombre = _nombreCtrl.text.trim();
    final ubicacion = _ubicacionCtrl.text.trim();
    final rango = _rangoCtrl.text.trim();

    if ([nombre, ubicacion, rango].any((e) => e.isEmpty) || _destino == null) {
      _showMsg('Completa los campos obligatorios');
      return;
    }

    await DatabaseHelper.instance.insertAlarma({
      'nombre': nombre,
      'ubicacion': ubicacion,
      'latitud': _destino!.latitude,
      'longitud': _destino!.longitude,
      'rango': rango,
      'activa': 0,
    });

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _rangoCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'MiFuente3Bold')),
      );

  Widget _mapWidget() => _destino == null
      ? Center(
          key: const ValueKey('empty'),
          child:
              Text('Busca una ubicación', style: Theme.of(context).textTheme.bodyMedium),
        )
      : GoogleMap(
          key: ValueKey(_destino),
          initialCameraPosition: CameraPosition(target: _destino!, zoom: 15),
          markers: _markers,
          circles: _circles,
          onMapCreated: (c) {
            _mapController = c;
            // Adjust initial zoom to show the entire circle
            _mapController?.animateCamera(
              CameraUpdate.newLatLngBounds(_computeCircleBounds(_destino!, _radius), 50),
            );
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Alarma', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Nombre de la alarma'),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _label('Ubicación'),
            LocationAutocomplete(
              controller: _ubicacionCtrl,
              apiKey: _apiKey,
              onLocationSelected: (latLng, _) => _updateDestino(latLng),
              initialValue: _ubicacionCtrl.text,
            ),
            const SizedBox(height: 16),
            _label('Rango de activación (m)'),
            TextField(
              controller: _rangoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _mapWidget(),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: FilledButton(
                onPressed: _saveAlarma,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 17),
                ),
                child: const Text(
                  'Crear Alarma',
                  style: TextStyle(fontSize: 18, fontFamily: 'MiFuente3Bold'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}