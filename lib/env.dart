// Google Maps API key.
// Prefer supplying this at build time with: --dart-define=GOOGLE_MAPS_API_KEY=<key>
// The default value below matches the previous inline key so existing runs keep working,
// but you should rotate and remove the hardcoded value for security.
final String googleMapsApiKey = const String.fromEnvironment(
	'GOOGLE_MAPS_API_KEY',
	defaultValue: 'AIzaSyB5Nc_EBy8tO9Wyh0K0B96RDkN9d-MET_4',
);

// Gemini API key used to call the Generative Language API.
// Prefer providing this at build time or via secure storage. Example for local builds:
// flutter run --dart-define=GEMINI_API_KEY=your_key_here
// The defaultValue keeps current behavior but please rotate the key and avoid committing it.
final String geminiApiKey = const String.fromEnvironment(
	'GEMINI_API_KEY',
	defaultValue: 'AIzaSyBGd9KC_n1FjSgUfn5_Np7XKP7AM2L98_Q',
);