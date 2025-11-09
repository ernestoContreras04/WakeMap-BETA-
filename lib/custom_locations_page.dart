import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tfg_definitivo2/database_helper.dart';
import 'package:tfg_definitivo2/widgets/glass_navbar.dart';
import 'package:geocoding/geocoding.dart' as geo;

class CustomLocationsPage extends StatefulWidget {
  const CustomLocationsPage({super.key});

  @override
  State<CustomLocationsPage> createState() => _CustomLocationsPageState();
}

class _CustomLocationsPageState extends State<CustomLocationsPage> {
  List<Map<String, dynamic>> _customLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomLocations();
  }

  Future<void> _loadCustomLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await DatabaseHelper.instance.getCustomLocations();
      setState(() {
        _customLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando ubicaciones: $e')),
        );
      }
    }
  }

  Future<void> _addCustomLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCustomLocationPage(),
      ),
    );

    if (result != null) {
      await _loadCustomLocations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación personalizada añadida'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editCustomLocation(Map<String, dynamic> location) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomLocationPage(location: location),
      ),
    );

    if (result != null) {
      await _loadCustomLocations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación personalizada actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteCustomLocation(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ubicación'),
        content: Text('¿Estás seguro de que quieres eliminar "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteCustomLocation(id);
      await _loadCustomLocations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
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
          SafeArea(
            child: Column(
              children: [
                _buildHeader(theme),
                Expanded(
                  child: _buildContent(theme),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassNavbar(
              currentIndex: 3,
            ),
          ),
          // Botón flotante posicionado arriba del navbar (80px de altura navbar + 20px margen)
          Positioned(
            right: 20,
            bottom: 100, // Altura aproximada del navbar (80px) + margen (20px)
            child: FloatingActionButton(
              onPressed: _addCustomLocation,
              backgroundColor: theme.colorScheme.primary,
              elevation: 4,
              child: const Icon(CupertinoIcons.add, color: Colors.white),
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
        children: [
          Flexible(
            child: Text(
              'Ubicaciones personalizadas',
              style: TextStyle(
                fontSize: 24, // Reducido ligeramente para evitar overflow
                fontWeight: FontWeight.w800,
                color: theme.textTheme.titleLarge?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_customLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.location_slash,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes ubicaciones personalizadas',
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade ubicaciones como "Trabajo" o "Casa"',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _customLocations.length,
      itemBuilder: (context, index) {
        final location = _customLocations[index];
        return _buildLocationCard(location, theme);
      },
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            CupertinoIcons.location_solid,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          location['nombre'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          location['ubicacion'],
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.pencil),
              onPressed: () => _editCustomLocation(location),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.delete, color: Colors.red),
              onPressed: () => _deleteCustomLocation(
                location['id'],
                location['nombre'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCustomLocationPage extends StatefulWidget {
  final Map<String, dynamic>? location;

  const AddCustomLocationPage({super.key, this.location});

  @override
  State<AddCustomLocationPage> createState() => _AddCustomLocationPageState();
}

class _AddCustomLocationPageState extends State<AddCustomLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _nameController.text = widget.location!['nombre'];
      _addressController.text = widget.location!['ubicacion'];
      _selectedLocation = LatLng(
        widget.location!['latitud'],
        widget.location!['longitud'],
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _selectLocationOnMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLocation: _selectedLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });

      // Obtener dirección desde coordenadas
      try {
        final places = await geo.placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (places.isNotEmpty) {
          final place = places.first;
          final addressParts = <String>[];
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
            if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
              addressParts.add(place.subThoroughfare!);
            }
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          _addressController.text = addressParts.isEmpty 
              ? '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}'
              : addressParts.join(', ');
        } else {
          _addressController.text = '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        _addressController.text = '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}';
      }
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una ubicación en el mapa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final locationData = {
        'nombre': _nameController.text.trim(),
        'ubicacion': _addressController.text.trim(),
        'latitud': _selectedLocation!.latitude,
        'longitud': _selectedLocation!.longitude,
      };

      if (widget.location != null) {
        locationData['id'] = widget.location!['id'];
        await DatabaseHelper.instance.updateCustomLocation(locationData);
      } else {
        await DatabaseHelper.instance.insertCustomLocation(locationData);
      }

      if (mounted) {
        Navigator.pop(context, locationData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location != null ? 'Editar ubicación' : 'Nueva ubicación'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Trabajo, Casa, Gimnasio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.tag),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                hintText: 'Se completará al seleccionar en el mapa',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.location),
              ),
              readOnly: true,
              onTap: _selectLocationOnMap,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectLocationOnMap,
              icon: const Icon(CupertinoIcons.map),
              label: const Text('Seleccionar en el mapa'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_selectedLocation != null) ...[
              const SizedBox(height: 24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation!,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: _selectedLocation!,
                      ),
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Guardar ubicación',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;

  const MapLocationPicker({super.key, this.initialLocation});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng? _selectedLocation;
  String _address = '';

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  Future<void> _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _address = 'Cargando...';
    });

    try {
      final places = await geo.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (places.isNotEmpty) {
        final place = places.first;
        final addressParts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            addressParts.add(place.subThoroughfare!);
          }
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        setState(() {
          _address = addressParts.isEmpty 
              ? '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'
              : addressParts.join(', ');
        });
      } else {
        setState(() {
          _address = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      setState(() {
        _address = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? const LatLng(40.4168, -3.7038), // Madrid por defecto
              zoom: 15,
            ),
            onTap: _onMapTapped,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                    ),
                  }
                : {},
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _address,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _selectedLocation);
                        },
                        child: const Text('Confirmar ubicación'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

