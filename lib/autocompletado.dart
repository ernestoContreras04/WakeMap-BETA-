import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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

  Future<List<dynamic>> _fetchSuggestions(String input) async {
    if (input.length < 3) {
      setState(() => _suggestions = []);
      return [];
    }

    setState(() => _searchingLocation = true);

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=${widget.apiKey}&types=geocode&language=es';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        return data['predictions'];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    } finally {
      setState(() => _searchingLocation = false);
    }
  }

  void _onChanged(String input) async {
    final results = await _fetchSuggestions(input);
    setState(() {
      _suggestions = results;
    });
  }

  Future<void> _selectSuggestion(dynamic suggestion) async {
    final placeId = suggestion['place_id'];

    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${widget.apiKey}&language=es';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final result = data['result'];
      final location = result['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);

      setState(() {
        widget.controller.text = result['formatted_address'];
        _suggestions = [];
      });

      widget.onLocationSelected(latLng, result['formatted_address']);
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
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: _searchingLocation
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
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
                  title: Text(s['description']),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          ),
      ],
    );
  }
}
