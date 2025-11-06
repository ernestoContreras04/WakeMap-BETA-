import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  // Fallback in-memory storage for web builds (sqflite is not available on web)
  final List<Map<String, dynamic>> _inMemoryAlarmas = <Map<String, dynamic>>[];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      // sqflite isn't supported on web; callers should use the same API but
      // operations will be served from an in-memory list.
      throw UnsupportedError('Database is not available on web. Use fallback methods.');
    }

    if (_database != null) return _database!;
    _database = await _initDB('alarmas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // await deleteDatabase(path);

    return await openDatabase(
      path, 
      version: 2, 
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
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Añadir campo sonido_id a la tabla existente
      await db.execute('ALTER TABLE alarmas ADD COLUMN sonido_id TEXT DEFAULT "default"');
    }
  }

  Future<int> insertAlarma(Map<String, dynamic> alarma) async {
    if (kIsWeb) {
      // assign a fake autoincrement id
      final nextId = (_inMemoryAlarmas.isEmpty) ? 1 : (_inMemoryAlarmas.map((a) => a['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      final copy = Map<String, dynamic>.from(alarma);
      copy['id'] = nextId;
      _inMemoryAlarmas.add(copy);
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
      return _inMemoryAlarmas.where((a) => (a['activa'] ?? 0) == 1).toList();
    }
    final db = await instance.database;
    return await db.query('alarmas', where: 'activa = ?', whereArgs: [1]);
  }

  Future<int> deleteAlarma(int id) async {
    if (kIsWeb) {
      _inMemoryAlarmas.removeWhere((a) => a['id'] == id);
      return 1;
    }
    final db = await instance.database;
    return await db.delete('alarmas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAlarma(Map<String, dynamic> alarma) async {
    if (kIsWeb) {
      final idx = _inMemoryAlarmas.indexWhere((a) => a['id'] == alarma['id']);
      if (idx != -1) {
        _inMemoryAlarmas[idx] = Map<String, dynamic>.from(alarma);
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
      // Para web, actualizar en memoria
      for (var alarma in _inMemoryAlarmas) {
        alarma['activa'] = (alarma['id'] == id && activar) ? 1 : 0;
      }
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
      return;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alarmas.db');
    await deleteDatabase(path);
    _database = null;
  }
}