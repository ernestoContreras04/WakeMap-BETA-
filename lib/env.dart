import 'package:flutter_dotenv/flutter_dotenv.dart';

final String googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'key-not-found';
