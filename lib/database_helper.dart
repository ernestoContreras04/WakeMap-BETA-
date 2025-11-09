import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  // Fallback storage for web builds (sqflite is not available on web)
  // Usamos SharedPreferences para persistencia en web
  final List<Map<String, dynamic>> _inMemoryAlarmas = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _inMemoryCustomLocations = <Map<String, dynamic>>[];
  bool _webDataLoaded = false;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      // sqflite isn't supported on web; callers should use the same API but
      // operations will be served from SharedPreferences-backed storage.
      if (!_webDataLoaded) {
        await _loadWebData();
      }
      throw UnsupportedError('Database is not available on web. Use fallback methods.');
    }

    if (_database != null) return _database!;
    _database = await _initDB('alarmas.db');
    return _database!;
  }

  /// Carga datos desde SharedPreferences en web
  Future<void> _loadWebData() async {
    if (!kIsWeb || _webDataLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar alarmas
      final alarmasJson = prefs.getString('web_alarmas');
      if (alarmasJson != null) {
        final List<dynamic> decoded = jsonDecode(alarmasJson);
        _inMemoryAlarmas.clear();
        _inMemoryAlarmas.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      }
      
      // Cargar ubicaciones personalizadas
      final locationsJson = prefs.getString('web_custom_locations');
      if (locationsJson != null) {
        final List<dynamic> decoded = jsonDecode(locationsJson);
        _inMemoryCustomLocations.clear();
        _inMemoryCustomLocations.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      }
      
      _webDataLoaded = true;
    } catch (e) {
      // Si hay error, continuar con listas vacías
      _webDataLoaded = true;
    }
  }

  /// Guarda datos en SharedPreferences en web
  Future<void> _saveWebData() async {
    if (!kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar alarmas
      final alarmasJson = jsonEncode(_inMemoryAlarmas);
      await prefs.setString('web_alarmas', alarmasJson);
      
      // Guardar ubicaciones personalizadas
      final locationsJson = jsonEncode(_inMemoryCustomLocations);
      await prefs.setString('web_custom_locations', locationsJson);
    } catch (e) {
      // Si hay error guardando, continuar
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // await deleteDatabase(path);

    return await openDatabase(
      path, 
      version: 3, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL';
    const intType = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
      CREATE TABLE alarmas (
        id $idType,
        nombre $textType,
        ubicacion $textType,
        latitud $realType,
        longitud $realType,
        rango $textType,
        activa $intType,
        sonido_id TEXT DEFAULT 'default'
      )
    ''');
    
    // Crear índices para optimizar consultas frecuentes
    await db.execute('CREATE INDEX idx_alarmas_activa ON alarmas(activa)');
    await db.execute('CREATE INDEX idx_alarmas_nombre ON alarmas(nombre)');
    
    // Crear tabla de ubicaciones personalizadas
    await db.execute('''
      CREATE TABLE custom_locations (
        id $idType,
        nombre $textType,
        ubicacion $textType,
        latitud $realType,
        longitud $realType
      )
    ''');
    
    // Índice para búsqueda rápida por nombre
    await db.execute('CREATE INDEX idx_custom_locations_nombre ON custom_locations(nombre)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Añadir campo sonido_id a la tabla existente
      await db.execute('ALTER TABLE alarmas ADD COLUMN sonido_id TEXT DEFAULT "default"');
    }
    if (oldVersion < 3) {
      // Crear tabla de ubicaciones personalizadas
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const realType = 'REAL';
      
      await db.execute('''
        CREATE TABLE custom_locations (
          id $idType,
          nombre $textType,
          ubicacion $textType,
          latitud $realType,
          longitud $realType
        )
      ''');
      
      await db.execute('CREATE INDEX idx_custom_locations_nombre ON custom_locations(nombre)');
    }
  }

  Future<int> insertAlarma(Map<String, dynamic> alarma) async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      // assign a fake autoincrement id
      final nextId = (_inMemoryAlarmas.isEmpty) ? 1 : (_inMemoryAlarmas.map((a) => a['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      final copy = Map<String, dynamic>.from(alarma);
      copy['id'] = nextId;
      _inMemoryAlarmas.add(copy);
      await _saveWebData();
      return nextId;
    }

    final db = await instance.database;
    return await db.insert(
      'alarmas',
      alarma,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAlarmas() async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      // Return a copy to mimic DB behavior
      final list = List<Map<String, dynamic>>.from(_inMemoryAlarmas);
      // sort by activa desc, nombre asc
      list.sort((a, b) {
        final aAct = (a['activa'] ?? 0) as int;
        final bAct = (b['activa'] ?? 0) as int;
        if (aAct != bAct) return bAct.compareTo(aAct);
        final aName = (a['nombre'] ?? '').toString();
        final bName = (b['nombre'] ?? '').toString();
        return aName.compareTo(bName);
      });
      return list;
    }

    final db = await instance.database;
    return await db.query('alarmas', orderBy: 'activa DESC, nombre ASC');
  }
  
  Future<List<Map<String, dynamic>>> getAlarmasActivas() async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      return _inMemoryAlarmas.where((a) => (a['activa'] ?? 0) == 1).toList();
    }
    final db = await instance.database;
    return await db.query('alarmas', where: 'activa = ?', whereArgs: [1]);
  }

  Future<int> deleteAlarma(int id) async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      _inMemoryAlarmas.removeWhere((a) => a['id'] == id);
      await _saveWebData();
      return 1;
    }
    final db = await instance.database;
    return await db.delete('alarmas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAlarma(Map<String, dynamic> alarma) async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      final idx = _inMemoryAlarmas.indexWhere((a) => a['id'] == alarma['id']);
      if (idx != -1) {
        _inMemoryAlarmas[idx] = Map<String, dynamic>.from(alarma);
        await _saveWebData();
        return 1;
      }
      return 0;
    }

    final db = await instance.database;
    return await db.update(
      'alarmas',
      alarma,
      where: 'id = ?',
      whereArgs: [alarma['id']],
    );
  }

  Future<void> updateAllAlarmasActiva(int id, bool activar) async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      // Para web, actualizar en memoria
      for (var alarma in _inMemoryAlarmas) {
        alarma['activa'] = (alarma['id'] == id && activar) ? 1 : 0;
      }
      await _saveWebData();
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      // Desactivar todas las alarmas primero
      await txn.update('alarmas', {'activa': 0});
      // Si se activa, activar solo la seleccionada
      if (activar) {
        await txn.update('alarmas', {'activa': 1}, where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  Future<void> deleteLocalDatabase() async {
    if (kIsWeb) {
      _inMemoryAlarmas.clear();
      _inMemoryCustomLocations.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('web_alarmas');
      await prefs.remove('web_custom_locations');
      _webDataLoaded = false;
      return;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alarmas.db');
    await deleteDatabase(path);
    _database = null;
  }

  // ==================== MÉTODOS PARA UBICACIONES PERSONALIZADAS ====================

  Future<int> insertCustomLocation(Map<String, dynamic> location) async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      final nextId = (_inMemoryCustomLocations.isEmpty) 
          ? 1 
          : (_inMemoryCustomLocations.map((l) => l['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      final copy = Map<String, dynamic>.from(location);
      copy['id'] = nextId;
      _inMemoryCustomLocations.add(copy);
      await _saveWebData();
      return nextId;
    }

    final db = await instance.database;
    return await db.insert(
      'custom_locations',
      location,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCustomLocations() async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      return List<Map<String, dynamic>>.from(_inMemoryCustomLocations);
    }

    final db = await instance.database;
    return await db.query('custom_locations', orderBy: 'nombre ASC');
  }

  /// Busca una ubicación personalizada por nombre (case-insensitive y flexible)
  /// Busca coincidencias exactas y también busca dentro del texto
  Future<Map<String, dynamic>?> getCustomLocationByName(String name) async {
    // Limpiar el nombre: quitar artículos y espacios extra
    String cleanName = name.toLowerCase().trim();
    cleanName = cleanName.replaceAll(RegExp(r'^(el |la |los |las |a |al |del |de |en )'), '');
    cleanName = cleanName.trim();
    
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      // Buscar coincidencia exacta primero
      var location = _inMemoryCustomLocations.firstWhere(
        (l) => (l['nombre'] as String).toLowerCase() == cleanName,
        orElse: () => <String, dynamic>{},
      );
      
      // Si no hay coincidencia exacta, buscar que el nombre esté contenido
      if (location.isEmpty) {
        location = _inMemoryCustomLocations.firstWhere(
          (l) {
            final locName = (l['nombre'] as String).toLowerCase();
            return locName.contains(cleanName) || cleanName.contains(locName);
          },
          orElse: () => <String, dynamic>{},
        );
      }
      
      return location.isEmpty ? null : location;
    }

    final db = await instance.database;
    
    // Primero buscar coincidencia exacta
    var results = await db.query(
      'custom_locations',
      where: 'LOWER(nombre) = ?',
      whereArgs: [cleanName],
      limit: 1,
    );
    
    // Si no hay coincidencia exacta, buscar que contenga el nombre
    if (results.isEmpty) {
      final allLocations = await db.query('custom_locations');
      for (var loc in allLocations) {
        final locName = (loc['nombre'] as String).toLowerCase();
        if (locName.contains(cleanName) || cleanName.contains(locName)) {
          return loc;
        }
      }
    }
    
    return results.isEmpty ? null : results.first;
  }

  Future<int> updateCustomLocation(Map<String, dynamic> location) async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      final idx = _inMemoryCustomLocations.indexWhere((l) => l['id'] == location['id']);
      if (idx != -1) {
        _inMemoryCustomLocations[idx] = Map<String, dynamic>.from(location);
        await _saveWebData();
        return 1;
      }
      return 0;
    }

    final db = await instance.database;
    return await db.update(
      'custom_locations',
      location,
      where: 'id = ?',
      whereArgs: [location['id']],
    );
  }

  Future<int> deleteCustomLocation(int id) async {
    if (kIsWeb) {
      if (!_webDataLoaded) await _loadWebData();
      _inMemoryCustomLocations.removeWhere((l) => l['id'] == id);
      await _saveWebData();
      return 1;
    }
    final db = await instance.database;
    return await db.delete('custom_locations', where: 'id = ?', whereArgs: [id]);
  }
}