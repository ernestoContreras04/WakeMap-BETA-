// Stub file para evitar errores de compilación cuando no estamos en web
// Este archivo se usa cuando compilamos para Android/iOS (cuando dart.library.html no está disponible)

// Stub para html.window - cuando se importa como 'import web_stub.dart as html', 
// se puede acceder a html.window
class WindowStub {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Exportar window como variable de nivel superior para que html.window funcione
final window = WindowStub();

// Stub para js_util - exportar como funciones de nivel superior para compatibilidad con imports con prefijo
// Nota: Cuando se importa con prefijo 'as js_util', estas funciones se acceden como js_util.hasProperty, etc.

// Stub para globalThis
dynamic get globalThis => null;

// Stub para hasProperty
bool hasProperty(dynamic object, String name) => false;

// Stub para getProperty
dynamic getProperty(dynamic object, String name) => null;

// Stub para dartify
dynamic dartify(dynamic object) => null;

// Stub para allowInterop
Function allowInterop(Function f) => f;

// Stub para callMethod
dynamic callMethod(dynamic object, String method, List<dynamic> args) => null;

