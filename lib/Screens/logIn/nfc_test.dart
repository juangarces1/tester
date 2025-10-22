import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/helpers/constans.dart';



class NfcTestPage extends StatefulWidget {
  const NfcTestPage({super.key});
  @override
  State<NfcTestPage> createState() => _NfcTestPageState();
}

class _NfcTestPageState extends State<NfcTestPage> {
  // ---- Estado NFC & UI
  bool _scanning = false;
  bool _continuous = false;
  bool _stopRequested = false;
  int _timeoutSeconds = 15;

  // anti-spam de lecturas en continuo
  String? _lastUidSeen;
  DateTime? _lastUidAt;
  final Duration _sameUidCooldown = const Duration(seconds: 2);

  Map<String, dynamic>? _lastTag;
  final List<Map<String, dynamic>> _logs = [];
  final List<String> _savedUids = [];

  // Acciones remotas
  bool _assigning = false;
  bool _testingLogin = false;

  // ---------- Helpers ----------
  void _safeSet(void Function() fn) { if (mounted) setState(fn); }
  void _addLog(String title, dynamic data) {
    _safeSet(() {
      _logs.insert(0, {
        'time': DateTime.now().toIso8601String(),
        'title': title,
        'data': data,
      });
    });
  }

  String _formatUid(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
  }

  // ---------- NFC ----------
  Future<void> _startScan() async {
    if (_scanning) return;
    _stopRequested = false;
    _safeSet(() => _scanning = true);

    try {
      final ava = await FlutterNfcKit.nfcAvailability;
      _addLog('Availability', ava.toString());
      if (ava != NFCAvailability.available) {
        Fluttertoast.showToast(msg: 'NFC no disponible: $ava');
        return;
      }

      do {
        _addLog('Action', 'Polling NFC (${_timeoutSeconds}s)...');
        NFCTag tag;

        try {
          tag = await FlutterNfcKit.poll(
            timeout: Duration(seconds: _timeoutSeconds),
            iosMultipleTagMessage: 'Detecté varias tarjetas, separa una sola.',
            androidPlatformSound: true,
          );
        } on Exception catch (e) {
          _addLog('Poll error', e.toString());
          if (_stopRequested || !_continuous) break;
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }

        final basic = <String, dynamic>{
          'id': _formatUid(tag.id),
          'type': tag.type.toString(),
          'standard': tag.standard,
          'atqa': tag.atqa,
          'sak': tag.sak,
          'historicalBytes': tag.historicalBytes,
          'hiLayerResponse': tag.hiLayerResponse,
          'protocolInfo': tag.protocolInfo,
          'applicationData': tag.applicationData,
          'manufacturer': tag.manufacturer,
          'systemCode': tag.systemCode,
          'dsfId': tag.dsfId,
          'ndefAvailable': tag.ndefAvailable,
          'ndefType': tag.ndefType,
          'ndefCapacity': tag.ndefCapacity,
          'ndefWritable': tag.ndefWritable,
          'ndefCanMakeReadOnly': tag.ndefCanMakeReadOnly,
          'mifare': tag.mifareInfo == null
              ? null
              : {
                  'type': tag.mifareInfo!.type,
                  'size': tag.mifareInfo!.size,
                  'blockSize': tag.mifareInfo!.blockSize,
                  'blockCount': tag.mifareInfo!.blockCount,
                  'sectorCount': tag.mifareInfo!.sectorCount,
                },
          'timestamp': DateTime.now().toIso8601String(),
        };

        _lastTag = basic;
        _addLog('Tag detected', basic);

        final uid = _formatUid(basic['id'] as String?);
        final now = DateTime.now();
        final sameAsLast = uid.isNotEmpty &&
            _lastUidSeen == uid &&
            _lastUidAt != null &&
            now.difference(_lastUidAt!) < _sameUidCooldown;

        if (!sameAsLast) {
          _lastUidSeen = uid;
          _lastUidAt = now;
          try { await HapticFeedback.selectionClick(); } catch (_) {}
          if (uid.isNotEmpty) {
            Fluttertoast.showToast(msg: 'UID: $uid');
          } else {
            Fluttertoast.showToast(msg: 'Tag leído sin UID visible');
          }
        }

        // NDEF (resumen)
        if (tag.ndefAvailable ?? false) {
          try {
            final ndefRecords = await FlutterNfcKit.readNDEFRawRecords();
            final recs = ndefRecords
                .map((r) => {
                      'type': r.type,
                      'identifierLen': r.identifier.length,
                      'payloadLen': r.payload.length,
                      'typeNameFormat': r.typeNameFormat.toString(),
                    })
                .toList();
            _addLog('NDEF summary', recs);
          } catch (e) {
            _addLog('NDEF read error', e.toString());
          }
        }

        try { await FlutterNfcKit.finish(); } catch (_) {}
        if (_continuous && !_stopRequested) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } while (_continuous && !_stopRequested);
    } finally {
      try { await FlutterNfcKit.finish(); } catch (_) {}
      _safeSet(() => _scanning = false);
    }
  }

  Future<void> _stopScan() async {
    _stopRequested = true;
    try { await FlutterNfcKit.finish(); } catch (_) {}
    _safeSet(() => _scanning = false);
  }

  // ---------- API: asignar tarjeta al usuario del Provider ----------
  Future<void> _assignCardToMe() async {
    if (_assigning) return;

    // 1) UID del último tag
    final uid = _formatUid(_lastTag?['id'] as String?);
    if (uid.isEmpty) {
      Fluttertoast.showToast(msg: 'Primero lee una tarjeta');
      return;
    }

     final clienteProv = context.read<CierreActivoProvider>();
     final int? cedula = clienteProv.cierreFinal!.cedulaempleado; // <-- REEMPLÁZALO (arriba) Y BORRA ESTA LÍNEA

    if (cedula == null) {
      Fluttertoast.showToast(msg: 'No se encontró cédula en el Provider');
      return;
    }

    _safeSet(() => _assigning = true);
    try {
      final uri = Uri.parse('${Constans.getAPIUrl()}/api/users/$cedula/cards');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      if (resp.statusCode == 204) {
        Fluttertoast.showToast(msg: 'Tarjeta asignada a $cedula');
        _addLog('Asignación OK', {'cedula': cedula, 'uid': uid});
      } else if (resp.statusCode == 409) {
        Fluttertoast.showToast(msg: 'Tarjeta ya asignada a otro empleado (409)');
        _addLog('Asignación conflicto', resp.body);
      } else if (resp.statusCode == 400) {
        Fluttertoast.showToast(msg: 'Solicitud inválida (400)');
        _addLog('Asignación inválida', resp.body);
      } else if (resp.statusCode == 403) {
        Fluttertoast.showToast(msg: 'Tarjeta revocada/perdida (403)');
        _addLog('Asignación denegada', resp.body);
      } else {
        Fluttertoast.showToast(msg: 'Error ${resp.statusCode}');
        _addLog('Asignación error', {'status': resp.statusCode, 'body': resp.body});
      }
    } catch (e) {
      _addLog('Asignación exception', e.toString());
      Fluttertoast.showToast(msg: 'Error asignando tarjeta: $e');
    } finally {
      _safeSet(() => _assigning = false);
    }
  }

  // ---------- API: probar login por tarjeta (devuelve empleado) ----------
  Future<void> _testLogin() async {
    if (_testingLogin) return;
    final uid = _formatUid(_lastTag?['id'] as String?);
    if (uid.isEmpty) {
      Fluttertoast.showToast(msg: 'Primero lee una tarjeta');
      return;
    }

    _safeSet(() => _testingLogin = true);
    try {
      final uri = Uri.parse('${Constans.getAPIUrl()}/api/users/login-card');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _addLog('Login OK', data);
        _showEmpleadoDialog(data['empleado'] as Map<String, dynamic>?);
      } else if (resp.statusCode == 404) {
        Fluttertoast.showToast(msg: 'Tarjeta no registrada (404)');
      } else if (resp.statusCode == 403) {
        Fluttertoast.showToast(msg: 'Tarjeta revocada/perdida (403)');
      } else {
        Fluttertoast.showToast(msg: 'Error ${resp.statusCode}');
      }
    } catch (e) {
      _addLog('Login exception', e.toString());
      Fluttertoast.showToast(msg: 'Error login: $e');
    } finally {
      _safeSet(() => _testingLogin = false);
    }
  }

  void _showEmpleadoDialog(Map<String, dynamic>? emp) {
    if (emp == null) {
      showDialog(context: context, builder: (_) => const AlertDialog(
        title: Text('Sin datos'),
        content: Text('El API no devolvió información del empleado.'),
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Empleado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Cédula', '${emp['cedula'] ?? '-'}'),
              _kv('Nombre', '${emp['nombre'] ?? '-'}'),
              _kv('Apellido 1', '${emp['apellido1'] ?? '-'}'),
              _kv('Apellido 2', '${emp['apellido2'] ?? '-'}'),
              _kv('Turno', '${emp['turno'] ?? '-'}'),
              _kv('Tipo', '${emp['tipoEmpleado'] ?? emp['tipoempleado'] ?? '-'}'),
              const SizedBox(height: 8),
              Text('${emp['nombreCompleto'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')) ],
        );
      },
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(width: 110, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(v)),
      ],
    ),
  );

  // ---------- UI ----------
  Widget _buildHeaderCard() {
    final uid = _formatUid(_lastTag?['id'] as String?);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.nfc, size: 20),
              const SizedBox(width: 8),
              const Text('Tarjeta', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_scanning)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            const SizedBox(height: 8),
            SelectableText(uid.isEmpty ? '—' : uid,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _pill('type', _lastTag?['type']),
              _pill('standard', _lastTag?['standard']),
              _pill('ndef', (_lastTag?['ndefAvailable']).toString()),
              if ((_lastTag?['mifare']) != null) _pill('mifare', (_lastTag?['mifare']['type']).toString()),
            ]),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: _scanning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(_scanning ? 'Escaneando...' : 'Leer'),
                  onPressed: _scanning ? null : _startScan,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Parar'),
                  onPressed: _scanning ? _stopScan : null,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copiar UID',
                  icon: const Icon(Icons.copy),
                  onPressed: uid.isEmpty ? null : () async {
                    await Clipboard.setData(ClipboardData(text: uid));
                    Fluttertoast.showToast(msg: 'UID copiado');
                  },
                ),
                IconButton(
                  tooltip: 'Guardar UID',
                  icon: const Icon(Icons.bookmark_add_outlined),
                  onPressed: uid.isEmpty ? null : () {
                    if (!_savedUids.contains(uid)) {
                      _safeSet(() => _savedUids.insert(0, uid));
                    }
                    Fluttertoast.showToast(msg: 'UID guardado');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Controles', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [
              const Text('Escaneo continuo'),
              const SizedBox(width: 8),
              Switch(value: _continuous, onChanged: (v) => _safeSet(() => _continuous = v)),
              const Spacer(),
              const Text('Timeout:'),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: _timeoutSeconds,
                items: const [10, 15, 20, 30]
                    .map((s) => DropdownMenuItem(value: s, child: Text('${s}s')))
                    .toList(),
                onChanged: (v) => _safeSet(() => _timeoutSeconds = v ?? 15),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    final uid = _formatUid(_lastTag?['id'] as String?);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              ElevatedButton.icon(
                icon: _assigning
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.link),
                label: const Text('Asignar a mi usuario'),
                onPressed: uid.isEmpty || _assigning ? null : _assignCardToMe,
              ),
              OutlinedButton.icon(
                icon: _testingLogin
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.verified_user_outlined),
                label: const Text('Probar login por tarjeta'),
                onPressed: uid.isEmpty || _testingLogin ? null : _testLogin,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text('Guardar últimos UIDs'),
                onPressed: _logs.isEmpty ? null : _saveFromLogs,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _saveFromLogs() {
    final uids = _logs
        .map((e) => e['data'])
        .whereType<Map<String, dynamic>>()
        .map((m) => m['id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();
    _safeSet(() => _savedUids.insertAll(0, uids.where((u) => !_savedUids.contains(u))));
    Fluttertoast.showToast(msg: 'UID(s) guardado(s): ${uids.length}');
  }

  Widget _buildSavedUidsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UIDs guardados', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_savedUids.isEmpty) const Text('— ninguno —'),
            ..._savedUids.map((u) => ListTile(
                  dense: true,
                  title: Text(u, style: const TextStyle(fontFamily: 'monospace')),
                  trailing: Wrap(spacing: 4, children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copiar',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: u));
                        Fluttertoast.showToast(msg: 'Copiado');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Eliminar',
                      onPressed: () => _safeSet(() => _savedUids.remove(u)),
                    ),
                  ]),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard() {
    return Card(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 240,
        child: _logs.isEmpty
            ? const Center(child: Text('Logs aparecerán aquí', style: TextStyle(color: Colors.black54)))
            : ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (_, i) {
                  final l = _logs[i];
                  return ListTile(
                    dense: true,
                    title: Text('${l['title']} — ${l['time']}', style: const TextStyle(fontSize: 12)),
                    subtitle: Text(
                      l['data'].toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _pill(String k, dynamic v) {
    final txt = v?.toString() ?? '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text('$k: $txt', style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  void dispose() {
    _stopRequested = true;
    FlutterNfcKit.finish().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarjeta NFC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Limpiar',
            onPressed: () {
              _safeSet(() {
                _logs.clear();
                _savedUids.clear();
                _lastTag = null;
              });
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 12),
          _buildControlsCard(),
          const SizedBox(height: 12),
          _buildActionsCard(),
          const SizedBox(height: 12),
          _buildSavedUidsCard(),
          const SizedBox(height: 12),
          _buildLogsCard(),
        ],
      ),
    );
  }
}
