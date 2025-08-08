import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'database_helper.dart';
import 'package:tfg_definitivo2/autocompletado.dart';

class EditAlarmaPage extends StatefulWidget {
  final Map<String, dynamic> alarma;
  final void Function(Map<String, dynamic> alarmaEliminada)? onDelete;

  const EditAlarmaPage({super.key, required this.alarma, this.onDelete});

  @override
  State<EditAlarmaPage> createState() => _EditAlarmaPageState();
}

class _EditAlarmaPageState extends State<EditAlarmaPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nombreController;
  late final TextEditingController _ubicacionController;
  late final TextEditingController _rangoController;

  late LatLng _alarmaLocation;
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Marker? _radiusMarker;

  double _radius = 100.0;
  bool _updatingFromMap = false;
  bool _updatingFromText = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final String apiKey = 'AIzaSyB5Nc_EBy8tO9Wyh0K0B96RDkN9d-MET_4';

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(text: widget.alarma['nombre']);
    _ubicacionController = TextEditingController(text: widget.alarma['ubicacion']);
    _rangoController = TextEditingController(text: widget.alarma['rango'].toString());

    _alarmaLocation = LatLng(
      widget.alarma['latitud'],
      widget.alarma['longitud'],
    );
    _radius = double.tryParse(widget.alarma['rango'].toString()) ?? 100.0;

    _markers.add(Marker(
      markerId: const MarkerId('destino'),
      position: _alarmaLocation,
      infoWindow: InfoWindow(title: widget.alarma['ubicacion']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
    ));

    _circles = {
      Circle(
        circleId: const CircleId('rango_activacion'),
        center: _alarmaLocation,
        radius: _radius,
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blueAccent,
        strokeWidth: 2,
      )
    };

    final offsetPos = _computeOffset(_alarmaLocation, _radius, 90);
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

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _rangoController.addListener(() {
      if (_updatingFromMap) return;
      final text = _rangoController.text;
      final newRadius = double.tryParse(text);
      if (newRadius != null) {
        _updatingFromText = true;
        _radius = newRadius;
        _updateCircleAndMarker();
        _updatingFromText = false;
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _rangoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

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

  void _updateRadius(LatLng newPos) {
    final distance = _calculateDistance(_alarmaLocation, newPos);
    setState(() {
      _radius = distance;
      _rangoController.text = _radius.toInt().toString();

      _circles = {
        Circle(
          circleId: const CircleId('rango_activacion'),
          center: _alarmaLocation,
          radius: _radius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blueAccent,
          strokeWidth: 2,
        )
      };

      final newOffset = _computeOffset(_alarmaLocation, _radius, 90);
      _markers.removeWhere((m) => m.markerId.value == 'radius_marker');
      _radiusMarker = _radiusMarker!.copyWith(positionParam: newOffset);
      _markers.add(_radiusMarker!);

      _updatingFromMap = false;

      // Adjust map zoom to show the entire circle
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(_computeCircleBounds(_alarmaLocation, _radius), 50),
      );
    });
  }

  void _updateCircleAndMarker() {
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('rango_activacion'),
          center: _alarmaLocation,
          radius: _radius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blueAccent,
          strokeWidth: 2,
        )
      };

      final newOffset = _computeOffset(_alarmaLocation, _radius, 90);
      _markers.removeWhere((m) => m.markerId.value == 'radius_marker');
      _radiusMarker = _radiusMarker!.copyWith(positionParam: newOffset);
      _markers.add(_radiusMarker!);

      // Adjust map zoom to show the entire circle
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(_computeCircleBounds(_alarmaLocation, _radius), 50),
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

  Future<void> _saveChanges() async {
    final nombre = _nombreController.text.trim();
    final ubicacion = _ubicacionController.text.trim();
    final rango = _rangoController.text.trim();

    if (nombre.isEmpty || ubicacion.isEmpty || rango.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa todos los campos')),
        );
      }
      return;
    }

    final updatedAlarma = {
      'id': widget.alarma['id'],
      'nombre': nombre,
      'ubicacion': ubicacion,
      'latitud': _alarmaLocation.latitude,
      'longitud': _alarmaLocation.longitude,
      'rango': rango,
      'activa': widget.alarma['activa'],
    };

    await DatabaseHelper.instance.updateAlarma(updatedAlarma);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteAlarma() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Alarma'),
        content: const Text('¿Estás seguro que quieres eliminar esta alarma?'),
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
    if (confirm == true) {
      await DatabaseHelper.instance.deleteAlarma(widget.alarma['id']);
      widget.onDelete?.call(widget.alarma);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _buildLabel(String text, {TextStyle? style}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: style ?? const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'MiFuente3Bold',
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Alarma', style: TextStyle(color: Colors.white)),
        backgroundColor: theme.colorScheme.primary,
        centerTitle: true,
        elevation: 3,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Nombre de la alarma'),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              _buildLabel('Ubicación'),
              LocationAutocomplete(
                controller: _ubicacionController,
                apiKey: apiKey,
                onLocationSelected: (latLng, address) {
                  setState(() {
                    _alarmaLocation = latLng;
                    _markers.removeWhere((m) => m.markerId.value == 'destino');
                    _markers.add(
                      Marker(
                        markerId: const MarkerId('destino'),
                        position: latLng,
                        infoWindow: InfoWindow(title: address),
                      ),
                    );
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngBounds(_computeCircleBounds(latLng, _radius), 50),
                    );
                    _updateCircleAndMarker();
                  });
                },
                initialValue: _ubicacionController.text,
              ),
              const SizedBox(height: 16),
              _buildLabel('Rango de activación (m)'),
              TextField(
                controller: _rangoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _alarmaLocation,
                    zoom: 15,
                  ),
                  markers: _markers,
                  circles: _circles,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Adjust initial zoom to show the entire circle
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngBounds(_computeCircleBounds(_alarmaLocation, _radius), 50),
                    );
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: _saveChanges,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 17,
                        ),
                      ),
                      child: const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'MiFuente1',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _deleteAlarma,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 17,
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.error,
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'MiFuente1',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}