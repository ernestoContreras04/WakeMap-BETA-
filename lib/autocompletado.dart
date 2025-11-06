// Conditional export: use the web implementation when `dart:html` is available,
// otherwise use the IO/native implementation that calls the Places REST API.
export 'autocompletado_io.dart' if (dart.library.html) 'autocompletado_web.dart';
