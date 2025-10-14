// =====================
// Modelos de entrada
// =====================

class NozzleConfig {
  final int nozzleNumber;         // 1..N
  final int pumpId;               // 'dispense' del JSON (1,2,...)
  final String? connector;        // 'A'/'B' (fallback para cara)
  final String fullAddress;       // "01-A-2-B"
  final int fuelCode;
  final double priceCash;
  final double priceCredit;
  final double priceDebit;
  final int priceDecimals;
  final int totalDecimals;
  final int volumeDecimals;

  NozzleConfig({
    required this.nozzleNumber,
    required this.pumpId,
    required this.connector,
    required this.fullAddress,
    required this.fuelCode,
    required this.priceCash,
    required this.priceCredit,
    required this.priceDebit,
    required this.priceDecimals,
    required this.totalDecimals,
    required this.volumeDecimals,
  });

  factory NozzleConfig.fromJson(Map<String, dynamic> j) => NozzleConfig(
        nozzleNumber: j['nozzleNumber'] as int,
        pumpId: j['dispense'] as int,
        connector: (j['connector'] as String?)?.trim(),
        fullAddress: j['fullAddress'] as String,
        fuelCode: j['fuelCode'] as int,
        priceCash: (j['unitPriceCash'] as num).toDouble(),
        priceCredit: (j['unitPriceCredit'] as num).toDouble(),
        priceDebit: (j['unitPriceDebit'] as num).toDouble(),
        priceDecimals: j['unitPriceDecimalPlaces'] as int,
        totalDecimals: j['totalFieldDecimalPlaces'] as int,
        volumeDecimals: j['volumeFieldDecimalPlaces'] as int,
      );
}

class HoseState {
  final int nozzleNumber;   // 1..N
  final String status;      // Available/Unpaid/Authorized/...

  HoseState({required this.nozzleNumber, required this.status});
}

class DispenserState {
  final int pumpSeq;               // 1..N (del JSON de estado: 'number')
  final String key;                // "D01"...
  final String status;             // estado del dispenser (global)
  final List<HoseState> hoses;

  DispenserState({
    required this.pumpSeq,
    required this.key,
    required this.status,
    required this.hoses,
  });

  factory DispenserState.fromJson(Map<String, dynamic> j) {
    List<HoseState> hs = [];
    for (final h in (j['hoses'] as List<dynamic>? ?? const [])) {
      // 'number' es 1..N; 'key' "Mxx" también se puede parsear si faltara 'number'
      final numOrNull = h['number'];
      int nozzleNumber;
      if (numOrNull is int) {
        nozzleNumber = numOrNull;
      } else {
        nozzleNumber = _parseMKeyToInt(h['key'] as String?);
      }
      hs.add(HoseState(
        nozzleNumber: nozzleNumber,
        status: (h['status'] as String?) ?? 'Unknown',
      ));
    }
    return DispenserState(
      pumpSeq: j['number'] as int,
      key: j['key'] as String,
      status: (j['status'] as String?) ?? 'Unknown',
      hoses: hs,
    );
  }
}

class PumpStateRoot {
  final List<DispenserState> dispensers;
  PumpStateRoot(this.dispensers);

  factory PumpStateRoot.fromJson(Map<String, dynamic> j) {
    final list = (j['dispensers'] as List<dynamic>? ?? const [])
        .map((e) => DispenserState.fromJson(e as Map<String, dynamic>))
        .toList();
    return PumpStateRoot(list);
  }
}

class PumpFacesEntry {
  final int nozzleNumber;  // id "1","2","3"... -> int
  final int face;          // numberOfFace (1/2)
  PumpFacesEntry({required this.nozzleNumber, required this.face});
}

class PumpFaces {
  final int pumpId;              // Surtidor físico (1..N)
  final String pumpName;         // "Surtidor 01"
  final int numberOfFaces;       // 2
  final List<PumpFacesEntry> mapping; // nozzle -> cara

  PumpFaces({
    required this.pumpId,
    required this.pumpName,
    required this.numberOfFaces,
    required this.mapping,
  });

  factory PumpFaces.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as List).cast<Map<String, dynamic>>();
    // Este JSON te puede venir por *pump*, aquí asumo que hay uno.
    final p = data.first;
    final pumpId = _parsePumpIdFromName(p['pumpName'] as String?); // "Surtidor 01" -> 1
    final faces = (p['numberOfFaces'] as int?) ?? 2;
    final m = <PumpFacesEntry>[];
    for (final d in (p['dispensers'] as List<dynamic>? ?? const [])) {
      final dj = d as Map<String, dynamic>;
      final idStr = dj['id'] as String;
      final face = dj['numberOfFace'] as int;
      m.add(PumpFacesEntry(nozzleNumber: int.parse(idStr), face: face));
    }
    return PumpFaces(
      pumpId: pumpId ?? 0,
      pumpName: (p['pumpName'] as String?) ?? '',
      numberOfFaces: faces,
      mapping: m,
    );
  }
}

// =====================
// Modelo unificado (salida)
// =====================

class HoseView {
  final int nozzleNumber;
  final String fullAddress;
  final int fuelCode;
  final double priceCash;
  final double priceCredit;
  final double priceDebit;
  final int priceDecimals;
  final int totalDecimals;
  final int volumeDecimals;
  final String status;

  HoseView({
    required this.nozzleNumber,
    required this.fullAddress,
    required this.fuelCode,
    required this.priceCash,
    required this.priceCredit,
    required this.priceDebit,
    required this.priceDecimals,
    required this.totalDecimals,
    required this.volumeDecimals,
    required this.status,
  });
}

class FaceView {
  final int pumpId;          // Surtidor físico
  final String? pumpName;    // Opcional si viene del JSON de faces
  final int face;            // 1/2
  final int pos;             // POS consecutivo global (1..N)
  final List<HoseView> hoses;

  FaceView({
    required this.pumpId,
    required this.pumpName,
    required this.face,
    required this.pos,
    required this.hoses,
  });
}

// =====================
// Merge principal
// =====================

class Merger {
  /// Recibe:
  ///  - configJson: { "data": [ ...nozzles... ] }
  ///  - stateJson:  { "dispensers": [ ... ] }
  ///  - facesJson:  { "data": [ { pumpName, numberOfFaces, dispensers:[{id, numberOfFace}]} ] }  (opcional)
  static List<FaceView> merge({
    required Map<String, dynamic> configJson,
    required Map<String, dynamic> stateJson,
    Map<String, dynamic>? facesJson, // puede venir por pump, ok
  }) {
    // 1) Parsear config nozzles
    final configs = (configJson['data'] as List<dynamic>)
        .map((e) => NozzleConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    // 2) Parsear estado
    final pumpState = PumpStateRoot.fromJson(stateJson);

    // Build: nozzleNumber -> status (prioriza hose.status; si no hay, usa dispenser.status)
    final stateByNozzle = <int, String>{};
    for (final d in pumpState.dispensers) {
      final dispStatus = d.status;
      for (final h in d.hoses) {
        stateByNozzle[h.nozzleNumber] = h.status.isNotEmpty ? h.status : dispStatus;
      }
    }

    // 3) Parsear faces (si viene)
    //    Mapeos: por pumpId (si logro inferir) y nozzle -> face
    final facesMappingByPump = <int, Map<int, int>>{}; // pumpId -> (nozzle -> face)
    String? pumpName;
    if (facesJson != null) {
      final pf = PumpFaces.fromJson(facesJson);
      pumpName = pf.pumpName;
      facesMappingByPump[pf.pumpId] = {
        for (final m in pf.mapping) m.nozzleNumber: m.face,
      };
    }

    // 4) Construir FaceView: primero agrupamos nozzles por (pumpId, face)
    //    La cara se obtiene: facesJson ? mapping : (connector A->1, B->2, otro->1)
    final grouped = <String, List<NozzleConfig>>{}; // key: "$pumpId|$face"
    for (final c in configs) {
      final pumpId = c.pumpId;
      final faceMap = facesMappingByPump[pumpId];
      final face = faceMap != null && faceMap.containsKey(c.nozzleNumber)
          ? faceMap[c.nozzleNumber]!
          : _inferFaceFromConnector(c.connector);

      final key = '$pumpId|$face';
      (grouped[key] ??= []).add(c);
    }

    // 5) Ordenamos por pumpId asc, face asc, y asignamos POS consecutivo global por cara
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final pa = int.parse(a.split('|')[0]);
        final fa = int.parse(a.split('|')[1]);
        final pb = int.parse(b.split('|')[0]);
        final fb = int.parse(b.split('|')[1]);
        final byPump = pa.compareTo(pb);
        return byPump != 0 ? byPump : fa.compareTo(fb);
      });

    int posCounter = 0;
    final result = <FaceView>[];

    for (final key in sortedKeys) {
      final parts = key.split('|');
      final pumpId = int.parse(parts[0]);
      final face = int.parse(parts[1]);

      // Hoses ordenadas por nozzleNumber
      final hoses = grouped[key]!..sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));

      final hoseViews = hoses.map((c) {
        final status = stateByNozzle[c.nozzleNumber] ?? 'Unknown';
        return HoseView(
          nozzleNumber: c.nozzleNumber,
          fullAddress: c.fullAddress,
          fuelCode: c.fuelCode,
          priceCash: c.priceCash,
          priceCredit: c.priceCredit,
          priceDebit: c.priceDebit,
          priceDecimals: c.priceDecimals,
          totalDecimals: c.totalDecimals,
          volumeDecimals: c.volumeDecimals,
          status: status,
        );
      }).toList();

      posCounter++; // asigna POS por cara
      result.add(FaceView(
        pumpId: pumpId,
        pumpName: pumpName, // si el facesJson venía de ese pump; si manejas varios, amplía
        face: face,
        pos: posCounter,
        hoses: hoseViews,
      ));
    }

    return result;
  }
}

// =====================
// Helpers
// =====================

int _inferFaceFromConnector(String? connector) {
  if (connector == null) return 1;
  final c = connector.toUpperCase().trim();
  if (c == 'A') return 1;
  if (c == 'B') return 2;
  // si algún fabricante decidió que 'C' también es una cara, le damos 1 por piedad
  return 1;
}

int _parseMKeyToInt(String? key) {
  if (key == null) return 0;
  final m = RegExp(r'(\d+)').firstMatch(key);
  return m != null ? int.parse(m.group(1)!) : 0;
}

int? _parsePumpIdFromName(String? pumpName) {
  if (pumpName == null) return null;
  final m = RegExp(r'(\d+)').firstMatch(pumpName);
  return m != null ? int.parse(m.group(1)!) : null;
}
