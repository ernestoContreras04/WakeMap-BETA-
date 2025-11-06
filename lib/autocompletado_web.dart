import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef OnLocationSelected = void Function(LatLng location, String address);

class LocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String apiKey;
  final OnLocationSelected onLocationSelected;
  final String? initialValue;

  const LocationAutocomplete({
    super.key,
    required this.controller,
    required this.apiKey,
    required this.onLocationSelected,
    this.initialValue,
  });

  @override
  State<LocationAutocomplete> createState() => _LocationAutocompleteState();
}

class _LocationAutocompleteState extends State<LocationAutocomplete> {
  List<dynamic> _suggestions = [];
  bool _searchingLocation = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<dynamic>> _fetchSuggestions(String input) async {
    if (input.length < 3) {
      if (mounted) setState(() => _suggestions = []);
      return [];
    }

    if (mounted) setState(() => _searchingLocation = true);

    try {
      // Wait briefly for the Google Maps JS to load (max ~3s)
      const int maxWaitMs = 3000;
      int waited = 0;
      while (waited < maxWaitMs) {
        final hasGoogle = js_util.hasProperty(js_util.globalThis, 'google') && js_util.hasProperty(js_util.getProperty(js_util.globalThis, 'google'), 'maps');
        if (hasGoogle) break;
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }

      final google = js_util.getProperty(js_util.globalThis, 'google');
      final maps = js_util.getProperty(google, 'maps');
      final places = js_util.getProperty(maps, 'places');
      final autoCtor = js_util.getProperty(places, 'AutocompleteService');
      final service = js_util.callConstructor(autoCtor, []);

      final request = js_util.jsify({
        'input': input,
        'types': ['geocode'],
        'language': 'es'
      });

      final completer = Completer<List<dynamic>>();

      js_util.callMethod(service, 'getPlacePredictions', [request, js_util.allowInterop((predictions, status) {
        if (predictions == null) {
          completer.complete([]);
        } else {
          // Convert JS objects to Dart structures
          final dartified = js_util.dartify(predictions) as List<dynamic>;
          completer.complete(List<dynamic>.from(dartified));
        }
      })]);

      final results = await completer.future;
      return results;
    } catch (e) {
      throw Exception('No se pudo conectar al servicio de autocompletado (web)');
    } finally {
      if (mounted) setState(() => _searchingLocation = false);
    }
  }

  void _onChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _fetchSuggestions(input);
        if (mounted) {
          setState(() {
            _suggestions = results;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    });
  }

  Future<void> _selectSuggestion(dynamic suggestion) async {
    final placeId = suggestion['place_id'];

    try {
      final google = js_util.getProperty(js_util.globalThis, 'google');
      final maps = js_util.getProperty(google, 'maps');
      final places = js_util.getProperty(maps, 'places');

      // PlacesService needs an HTML element; create a hidden div
      final container = html.DivElement();
      js_util.callMethod(html.document.body!, 'append', [container]);

      final placesCtor = js_util.getProperty(places, 'PlacesService');
      final service = js_util.callConstructor(placesCtor, [container]);

      final request = js_util.jsify({
        'placeId': placeId,
        'fields': ['formatted_address', 'geometry']
      });

      final completer = Completer<Map<String, dynamic>>();

      js_util.callMethod(service, 'getDetails', [request, js_util.allowInterop((result, status) {
        if (result == null) {
          completer.completeError('No se obtuvieron detalles');
        } else {
          completer.complete(js_util.dartify(result) as Map<String, dynamic>);
        }
      })]);

      final data = await completer.future;
      final location = data['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);

      setState(() {
        widget.controller.text = data['formatted_address'];
        _suggestions = [];
      });

      widget.onLocationSelected(latLng, data['formatted_address']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener detalles del lugar')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2C2C2E)
                : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _searchingLocation
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : null,
          ),
          onChanged: _onChanged,
          textInputAction: TextInputAction.next,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.shade200,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return ListTile(
                  title: Text(
                    s['description'],
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          ),
      ],
    );
  }
}
