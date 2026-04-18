import 'package:flutter/foundation.dart';
import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/local_db/clientes_db.dart';

/// Capa entre el backend (ApiHelper) y el store local (ClientesDb).
/// Todas las pantallas deben hablar CON el provider, el provider con el repository,
/// y el repository decide si tirar a la API o al cache local.
class ClientesRepository {
  ClientesRepository({ClientesDb? db}) : _db = db ?? ClientesDb.instance;

  final ClientesDb _db;

  // ─────────────────────── SYNC (API → local DB) ───────────────────────

  /// Carga COMPLETA paginada: limpia el cache local y re-baja todo.
  /// Usar sólo cuando quieras reset total (ej. botón "reparar").
  Future<SyncResult> syncContadoFull({
    int pageSize = 200,
    void Function(int cargados, int total)? onProgress,
  }) async {
    debugPrint('🔄 [ClientesRepo] syncContadoFull iniciado');
    int page = 1;
    int total = 0;
    int cargados = 0;

    while (true) {
      final Response resp = await ApiHelper.getClienteContadoPaged(
        page: page,
        pageSize: pageSize,
      );
      if (!resp.isSuccess) {
        return SyncResult(ok: false, message: resp.message, cargados: cargados);
      }
      final result = resp.result as Map<String, dynamic>;
      final pagina = (result['clientes'] as List).cast<Cliente>();
      total = result['totalRecords'] as int? ?? 0;
      final totalPages = result['totalPages'] as int? ?? 0;

      if (pagina.isEmpty && page == 1) {
        // nada que sincronizar
        break;
      }

      if (page == 1) {
        // primera página: limpiar antes de poblar
        await _db.deleteAllContado();
      }

      await _db.upsertContadoBatch(pagina);
      cargados += pagina.length;
      onProgress?.call(cargados, total);

      if (page >= totalPages) break;
      page++;
    }

    debugPrint('✅ [ClientesRepo] syncContadoFull: $cargados clientes');
    return SyncResult(ok: true, cargados: cargados);
  }

  /// Sync incremental: trae solo los clientes con id > maxLocal.
  /// Usa el campo `codigo` del Cliente como id numérico (Cliente.codigo == id BD).
  Future<SyncResult> syncContadoIncremental({int pageSize = 200}) async {
    final maxLocal = await _db.maxCodigoNumericoContado();
    debugPrint('♻️ [ClientesRepo] syncContadoIncremental desde minId=$maxLocal');

    int page = 1;
    int cargados = 0;

    while (true) {
      final Response resp = await ApiHelper.getClienteContadoPaged(
        page: page,
        pageSize: pageSize,
        minId: maxLocal,
      );
      if (!resp.isSuccess) {
        return SyncResult(ok: false, message: resp.message, cargados: cargados);
      }
      final result = resp.result as Map<String, dynamic>;
      final pagina = (result['clientes'] as List).cast<Cliente>();
      final totalPages = result['totalPages'] as int? ?? 0;

      if (pagina.isNotEmpty) {
        await _db.upsertContadoBatch(pagina);
        cargados += pagina.length;
      }

      if (page >= totalPages || pagina.isEmpty) break;
      page++;
    }

    debugPrint('✅ [ClientesRepo] syncContadoIncremental: +$cargados clientes');
    return SyncResult(ok: true, cargados: cargados);
  }

  /// Decide automáticamente: si el cache está vacío → full. Sino → incremental.
  Future<SyncResult> syncContadoSmart({int pageSize = 200}) async {
    final count = await _db.countContado();
    if (count == 0) {
      return syncContadoFull(pageSize: pageSize);
    }
    return syncContadoIncremental(pageSize: pageSize);
  }

  // ─────────────────────── READ ────────────────────────────────────────

  Future<List<Cliente>> searchContado(String query, {int limit = 50}) =>
      _db.searchContado(query, limit: limit);

  /// Upsert de un solo cliente — usado al crear/editar desde la UI sin
  /// re-sincronizar todo el backend.
  Future<void> upsertContadoSingle(Cliente c) => _db.upsertContadoBatch([c]);

  Future<Cliente?> getContadoByCodigo(String codigo) =>
      _db.findContadoByCodigo(codigo);

  Future<Cliente?> getContadoByDocumento(String doc) =>
      _db.findContadoByDocumento(doc);

  Future<Cliente?> getContadoByFrecuente(String codFrec) =>
      _db.findContadoByFrecuente(codFrec);

  Future<int> countContado() => _db.countContado();

  Future<List<Cliente>> getAllContado() => _db.getAllContado();
}

/// Resultado simple de un sync.
class SyncResult {
  final bool ok;
  final int cargados;
  final String? message;
  SyncResult({required this.ok, this.cargados = 0, this.message});
}
