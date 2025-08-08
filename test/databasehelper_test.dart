import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tfg_definitivo2/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbHelper = DatabaseHelper.instance;

  setUp(() async {
    await dbHelper.deleteLocalDatabase();
  });

  test('Insertar y obtener alarma', () async {
    final alarma = {
      'nombre': 'Alarma Test',
      'ubicacion': 'Lugar Test',
      'latitud': 12.34,
      'longitud': 56.78,
      'rango': '100',
      'activa': 0,
    };

    final id = await dbHelper.insertAlarma(alarma);
    expect(id, isNonZero);

    final alarmas = await dbHelper.getAlarmas();
    expect(alarmas, isNotEmpty);
    expect(alarmas.first['nombre'], equals('Alarma Test'));
  });

  test('Actualizar alarma', () async {
    final id = await dbHelper.insertAlarma({
      'nombre': 'Alarma 1',
      'ubicacion': 'Loc 1',
      'latitud': 1.0,
      'longitud': 2.0,
      'rango': '50',
      'activa': 0,
    });

    final updateCount = await dbHelper.updateAlarma({
      'id': id,
      'nombre': 'Alarma Actualizada',
      'ubicacion': 'Loc 1',
      'latitud': 1.0,
      'longitud': 2.0,
      'rango': '50',
      'activa': 1,
    });

    expect(updateCount, equals(1));

    final alarmas = await dbHelper.getAlarmas();
    expect(alarmas.first['nombre'], equals('Alarma Actualizada'));
    expect(alarmas.first['activa'], equals(1));
  });

  test('Eliminar alarma', () async {
    final id = await dbHelper.insertAlarma({
      'nombre': 'Alarma a eliminar',
      'ubicacion': 'Loc',
      'latitud': 1.0,
      'longitud': 2.0,
      'rango': '50',
      'activa': 0,
    });

    final deletedCount = await dbHelper.deleteAlarma(id);
    expect(deletedCount, equals(1));

    final alarmas = await dbHelper.getAlarmas();
    expect(alarmas.any((a) => a['id'] == id), isFalse);
  });
}
