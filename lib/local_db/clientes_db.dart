import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:tester/Models/FuelRed/cliente.dart';

/// SQLite local para cachear clientes contado (16k+ filas).
///
/// Reemplaza el esquema anterior (JSON file en /documents) porque:
///   - Búsqueda por nombre/documento/codigo frecuente con índice → milisegundos.
///   - Sync incremental barato: no re-serializa ni re-escribe 16k items.
///   - Upserts atómicos por codigo → soporta ediciones futuras (updatedAt).
class ClientesDb {
  ClientesDb._();
  static final ClientesDb instance = ClientesDb._();

  Database? _db;

  /// Tabla + índices. La lista real de columnas es mínima — los campos
  /// completos del Cliente viven en `raw_json` para no perder nada.
  static const _schema = '''
    CREATE TABLE clientes_contado (
      codigo              TEXT PRIMARY KEY,
      documento           TEXT,
      nombre              TEXT,
      email               TEXT,
      telefono            TEXT,
      codigo_frecuente    TEXT,
      codigo_tipo_id      TEXT,
      raw_json            TEXT NOT NULL,
      updated_at          INTEGER NOT NULL
    );
  ''';

  static const _indexes = [
    'CREATE INDEX IF NOT EXISTS ix_contado_nombre    ON clientes_contado(nombre COLLATE NOCASE);',
    'CREATE INDEX IF NOT EXISTS ix_contado_documento ON clientes_contado(documento);',
    'CREATE INDEX IF NOT EXISTS ix_contado_frec      ON clientes_contado(codigo_frecuente);',
  ];

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'fuelred_clientes.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(_schema);
        for (final ix in _indexes) {
          await db.execute(ix);
        }
      },
    );
  }

  // ─────────────────────────── WRITE ────────────────────────────────

  /// Inserta / actualiza una batch de clientes en una transacción.
  /// El JSON completo se guarda en `raw_json` para reconstruir el Cliente.
  Future<void> upsertContadoBatch(List<Cliente> clientes) async {
    if (clientes.isEmpty) return;
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await database.transaction((tx) async {
      final batch = tx.batch();
      for (final c in clientes) {
        final codigo = c.codigo.trim();
        if (codigo.isEmpty) continue;
        batch.insert(
          'clientes_contado',
          {
            'codigo': codigo,
            'documento': c.documento,
            'nombre': c.nombre,
            'email': c.email,
            'telefono': c.telefono,
            'codigo_frecuente': c.codigoFrecuente,
            'codigo_tipo_id': c.codigoTipoID,
            'raw_json': jsonEncode(c.toJson()),
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteAllContado() async {
    final database = await db;
    await database.delete('clientes_contado');
  }

  // ─────────────────────────── READ ─────────────────────────────────

  Future<int> countContado() async {
    final database = await db;
    final rows = await database.rawQuery('SELECT COUNT(*) AS c FROM clientes_contado');
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Devuelve el MAX(codigo cast int) — útil para sync incremental por minId.
  /// Como `codigo` es TEXT con valores numéricos, casteamos en la query.
  Future<int> maxCodigoNumericoContado() async {
    final database = await db;
    final rows = await database.rawQuery(
        'SELECT COALESCE(MAX(CAST(codigo AS INTEGER)), 0) AS m FROM clientes_contado');
    return (rows.first['m'] as int?) ?? 0;
  }

  Future<Cliente?> findContadoByCodigo(String codigo) async {
    final database = await db;
    final rows = await database.query(
      'clientes_contado',
      columns: ['raw_json'],
      where: 'codigo = ?',
      whereArgs: [codigo.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRawJson(rows.first['raw_json'] as String);
  }

  Future<Cliente?> findContadoByDocumento(String documento) async {
    final database = await db;
    final rows = await database.query(
      'clientes_contado',
      columns: ['raw_json'],
      where: 'documento = ?',
      whereArgs: [documento.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRawJson(rows.first['raw_json'] as String);
  }

  Future<Cliente?> findContadoByFrecuente(String codFrec) async {
    final database = await db;
    final rows = await database.query(
      'clientes_contado',
      columns: ['raw_json'],
      where: 'codigo_frecuente = ?',
      whereArgs: [codFrec.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRawJson(rows.first['raw_json'] as String);
  }

  /// Buscador por nombre o documento (LIKE con índice NOCASE en nombre).
  /// Orden: mejor match primero (prefijo > sufijo).
  Future<List<Cliente>> searchContado(String query, {int limit = 50}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final database = await db;
    final like = '%$q%';
    final prefix = '$q%';
    final rows = await database.rawQuery(
      '''
      SELECT raw_json
      FROM clientes_contado
      WHERE nombre LIKE ? COLLATE NOCASE
         OR documento LIKE ?
         OR codigo = ?
         OR codigo_frecuente = ?
      ORDER BY
        CASE
          WHEN nombre LIKE ? COLLATE NOCASE THEN 0   -- empieza con
          WHEN documento LIKE ? THEN 1                 -- docu empieza con
          ELSE 2
        END,
        nombre COLLATE NOCASE
      LIMIT ?
      ''',
      [like, like, q, q, prefix, prefix, limit],
    );
    return rows
        .map((r) => _fromRawJson(r['raw_json'] as String))
        .whereType<Cliente>()
        .toList();
  }

  /// Devuelve TODOS los contado — solo usar si el consumidor realmente los necesita
  /// (ej. lista completa en pantalla admin). Evitar en UIs de búsqueda.
  Future<List<Cliente>> getAllContado() async {
    final database = await db;
    final rows = await database.query(
      'clientes_contado',
      columns: ['raw_json'],
      orderBy: 'nombre COLLATE NOCASE',
    );
    return rows
        .map((r) => _fromRawJson(r['raw_json'] as String))
        .whereType<Cliente>()
        .toList();
  }

  // ─────────────────────────── HELPERS ──────────────────────────────

  Cliente? _fromRawJson(String raw) {
    try {
      return Cliente.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('ClientesDb: raw_json malformado: $e');
      return null;
    }
  }
}
