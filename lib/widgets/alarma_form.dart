import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:tfg_definitivo2/autocompletado.dart';
import 'package:tfg_definitivo2/database_helper.dart';
import 'package:tfg_definitivo2/env.dart';

class AlarmaForm extends StatefulWidget {
  final Map<String, dynamic>? alarma;

  const AlarmaForm({super.key, this.alarma});

  @override
  State<AlarmaForm> createState() => _AlarmaFormState();
}

class _AlarmaFormState extends State<AlarmaForm> {
  final _formKey = GlobalKey<FormState>();
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

  bool get _isEditMode => widget.alarma != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nombreCtrl.text = widget.alarma!['nombre'];
      _ubicacionCtrl.text = widget.alarma!['ubicacion'];
      _rangoCtrl.text = widget.alarma!['rango'].toString();
      _destino = LatLng(
        widget.alarma!['latitud'],
        widget.alarma!['longitud'],
      );
      _radius = double.tryParse(widget.alarma!['rango'].toString()) ?? 100.0;
      _loading = false;
      _updateMarkersAndCircles();
    } else {
      _initLocation();
    }

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
    try {
      if (await _location.requestPermission() != loc.PermissionStatus.granted) {
        _showMsg('Permiso de ubicación denegado');
        if (mounted) setState(() => _loading = false);
        return;
      }
      final locData = await _location.getLocation();
      if (mounted) {
        setState(() {
          _loading = false;
          _updateDestino(LatLng(locData.latitude!, locData.longitude!));
        });
      }
    } catch (e) {
      _showMsg('Error al obtener la ubicación');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateMarkersAndCircles() {
    if (_destino == null) return;
    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('destino'),
      position: _destino!,
      infoWindow: InfoWindow(title: _ubicacionCtrl.text),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
    ));
    _updateCircleAndMarker();
  }

  void _updateDestino(LatLng latLng) {
    if (!mounted) return;
    setState(() {
      _destino = latLng;
      _updateMarkersAndCircles();
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
      _updateCircleAndMarker();
      _updatingFromMap = false;
    });
  }

  void _updateCircleAndMarker() {
    if (_destino == null) return;
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
      _radiusMarker = Marker(
        markerId: const MarkerId('radius_marker'),
        position: newOffset,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onDrag: (newPos) {
          _updatingFromMap = true;
          _updateRadius(newPos);
        },
      );
      _markers.add(_radiusMarker!);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_computeCircleBounds(_destino!, _radius), 50),
      );
    });
  }

  Future<void> _saveAlarma() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final nombre = _nombreCtrl.text.trim();
    final ubicacion = _ubicacionCtrl.text.trim();
    final rango = _rangoCtrl.text.trim();

    if (_destino == null) {
      _showMsg('Selecciona una ubicación');
      return;
    }

    final alarmaData = {
      'nombre': nombre,
      'ubicacion': ubicacion,
      'latitud': _destino!.latitude,
      'longitud': _destino!.longitude,
      'rango': rango,
      'activa': _isEditMode ? widget.alarma!['activa'] : 0,
    };

    if (_isEditMode) {
      await DatabaseHelper.instance.updateAlarma({
        'id': widget.alarma!['id'],
        ...alarmaData,
      });
    } else {
      await DatabaseHelper.instance.insertAlarma(alarmaData);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteAlarma() async {
    if (!_isEditMode) return;

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
      await DatabaseHelper.instance.deleteAlarma(widget.alarma!['id']);
      if (mounted) Navigator.pop(context, true); // Pop twice to go back to home
    }
  }


  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _rangoCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
      ? const Center(child: CupertinoActivityIndicator())
      : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nombre de la alarma'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 20),
                _buildLabel('Ubicación'),
                const SizedBox(height: 8),
                LocationAutocomplete(
                  controller: _ubicacionCtrl,
                  apiKey: googleMapsApiKey,
                  onLocationSelected: (latLng, _) => _updateDestino(latLng),
                  initialValue: _ubicacionCtrl.text,
                ),
                const SizedBox(height: 20),
                _buildLabel('Rango de activación (m)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rangoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 24),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _destino == null
                      ? Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Text(
                              'Busca una ubicación',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(target: _destino!, zoom: 15),
                          markers: _markers,
                          circles: _circles,
                          onMapCreated: (c) {
                            _mapController = c;
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngBounds(_computeCircleBounds(_destino!, _radius), 50),
                            );
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                        ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: ElevatedButton(
                          onPressed: _saveAlarma,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isEditMode ? 'Guardar Cambios' : 'Crear Alarma',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_isEditMode) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red),
                          ),
                          child: OutlinedButton(
                            onPressed: _deleteAlarma,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Eliminar Alarma',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  LatLngBounds _computeCircleBounds(LatLng center, double radius) {
    final north = _computeOffset(center, radius * 1.1, 0);
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

  double _calculateDistance(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
  }

  LatLng _computeOffset(LatLng origin, double distance, double bearing) {
    const earthRadius = 6378137.0;
    final bearingRad = bearing * pi / 180;
    final latRad = origin.latitude * pi / 180;
    final lngRad = origin.longitude * pi / 180;
    final newLat = asin(sin(latRad) * cos(distance / earthRadius) + cos(latRad) * sin(distance / earthRadius) * cos(bearingRad));
    final newLng = lngRad + atan2(sin(bearingRad) * sin(distance / earthRadius) * cos(latRad), cos(distance / earthRadius) - sin(latRad) * sin(newLat));
    return LatLng(newLat * 180 / pi, newLng * 180 / pi);
  }
}
