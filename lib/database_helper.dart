import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('alarmas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // await deleteDatabase(path);

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
        activa $intType
      )
    ''');
    
    // Crear índices para optimizar consultas frecuentes
    await db.execute('CREATE INDEX idx_alarmas_activa ON alarmas(activa)');
    await db.execute('CREATE INDEX idx_alarmas_nombre ON alarmas(nombre)');
  }

  Future<int> insertAlarma(Map<String, dynamic> alarma) async {
    final db = await instance.database;
    return await db.insert(
      'alarmas',
      alarma,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAlarmas() async {
    final db = await instance.database;
    return await db.query('alarmas', orderBy: 'activa DESC, nombre ASC');
  }
  
  Future<List<Map<String, dynamic>>> getAlarmasActivas() async {
    final db = await instance.database;
    return await db.query('alarmas', where: 'activa = ?', whereArgs: [1]);
  }

  Future<int> deleteAlarma(int id) async {
    final db = await instance.database;
    return await db.delete('alarmas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAlarma(Map<String, dynamic> alarma) async {
    final db = await instance.database;
    return await db.update(
      'alarmas',
      alarma,
      where: 'id = ?',
      whereArgs: [alarma['id']],
    );
  }

  Future<void> deleteLocalDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alarmas.db');
    await deleteDatabase(path);
    _database = null;
  }
}