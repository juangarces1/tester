# Integrar endpoint /api/dispensers/station-map en Flutter

## Contexto

YAM ahora tiene un endpoint que devuelve el `stationMap` ya construido:
- **Endpoint:** `GET /api/dispensers/station-map`
- **Cache estados:** 2 segundos (Horustec)
- **Cache mappings:** Permanente (DB)

Flutter ya no necesita procesar nada, solo recibir y usar.

---

## Paso 1: Agregar URL de YAM en Constans

**Archivo:** `lib/helpers/constans.dart`

```dart
class Constans {
  // ... existente ...

  // Agregar URL de YAM
  static String baseUrlYam = 'http://TU_IP:8088/api/';
}
```

---

## Paso 2: Crear modelos con fromJson

**Archivo:** `lib/Models/station_map_response.dart` (nuevo)

```dart
import 'package:flutter/material.dart';

class FuelDto {
  final String name;
  final String color;

  const FuelDto({required this.name, required this.color});

  factory FuelDto.fromJson(Map<String, dynamic> json) {
    return FuelDto(
      name: json['name'] ?? 'Desconocido',
      color: json['color'] ?? '#808080',
    );
  }

  Color get colorValue {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class HosePhysicalDto {
  final int nozzleNumber;
  final String hoseKey;
  final FuelDto fuel;
  final String status;
  final int? dispenserNumber;
  final String? dispenserKey;
  final num? totalVolume;
  final num? totalAmount;

  const HosePhysicalDto({
    required this.nozzleNumber,
    required this.hoseKey,
    required this.fuel,
    required this.status,
    this.dispenserNumber,
    this.dispenserKey,
    this.totalVolume,
    this.totalAmount,
  });

  factory HosePhysicalDto.fromJson(Map<String, dynamic> json) {
    return HosePhysicalDto(
      nozzleNumber: json['nozzleNumber'] ?? 0,
      hoseKey: json['hoseKey'] ?? '',
      fuel: FuelDto.fromJson(json['fuel'] ?? {}),
      status: json['status'] ?? 'unknown',
      dispenserNumber: json['dispenserNumber'],
      dispenserKey: json['dispenserKey'],
      totalVolume: json['totalVolume'],
      totalAmount: json['totalAmount'],
    );
  }
}

class PositionPhysicalDto {
  final int number;
  final int pumpId;
  final String pumpName;
  final int faceIndex;
  final String faceLabel;
  final String faceDescription;
  final List<HosePhysicalDto> hoses;

  const PositionPhysicalDto({
    required this.number,
    required this.pumpId,
    required this.pumpName,
    required this.faceIndex,
    required this.faceLabel,
    required this.faceDescription,
    required this.hoses,
  });

  factory PositionPhysicalDto.fromJson(Map<String, dynamic> json) {
    return PositionPhysicalDto(
      number: json['number'] ?? 0,
      pumpId: json['pumpId'] ?? 0,
      pumpName: json['pumpName'] ?? '',
      faceIndex: json['faceIndex'] ?? 1,
      faceLabel: json['faceLabel'] ?? '',
      faceDescription: json['faceDescription'] ?? '',
      hoses: (json['hoses'] as List? ?? [])
          .map((h) => HosePhysicalDto.fromJson(h))
          .toList(),
    );
  }
}

class StationMapResponse {
  final Map<int, PositionPhysicalDto> stationMap;

  const StationMapResponse({required this.stationMap});

  factory StationMapResponse.fromJson(Map<String, dynamic> json) {
    final mapJson = json['stationMap'] as Map<String, dynamic>? ?? {};
    return StationMapResponse(
      stationMap: mapJson.map((key, value) => MapEntry(
        int.parse(key),
        PositionPhysicalDto.fromJson(value),
      )),
    );
  }
}
```

---

## Paso 3: Agregar método en ApiHelper

**Archivo:** `lib/helpers/api_helper.dart`

```dart
import '../Models/station_map_response.dart';

// Agregar este método
static Future<Map<int, PositionPhysicalDto>> getStationMap() async {
  final url = Uri.parse('${Constans.baseUrlYam}dispensers/station-map');

  final res = await http.get(url).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw Exception('Timeout al obtener station-map'),
  );

  if (res.statusCode == 200) {
    final json = jsonDecode(res.body);
    final response = StationMapResponse.fromJson(json);
    return response.stationMap;
  }

  throw Exception('Error al obtener station-map: HTTP ${res.statusCode}');
}
```

---

## Paso 4: Modificar MapProvider

**Archivo:** `lib/Providers/map_provider.dart`

### Opcion A: Reemplazar completamente loadMapDirect()

```dart
/// NUEVO: Usa el endpoint centralizado de YAM
Future<void> loadMapDirect() async {
  if (_pollInProgress) {
    debugPrint('⏭️ [MapProvider] Poll saltado (anterior aún en curso)');
    return;
  }
  _pollInProgress = true;
  _pollAttempts++;
  debugPrint('📡 [MapProvider] Poll #$_pollAttempts iniciando...');

  final isFirstLoad = _stationMap == null;
  if (isFirstLoad) {
    _loading = true;
    _error = null;
    _toastShown = false;
    notifyListeners();
  }

  try {
    // UNA sola llamada a YAM - devuelve todo listo
    final stationMap = await ApiHelper.getStationMap();

    if (stationMap.isEmpty) {
      _pollEmptyResponses++;
      debugPrint('⚠️ [MapProvider] Poll #$_pollAttempts → VACÍO');
    } else {
      // Convertir de PositionPhysicalDto a PositionPhysical si es necesario
      // O usar directamente si los tipos son compatibles
      _stationMap = _convertToPositionPhysical(stationMap);
      _error = null;
      _pollSuccess++;
      debugPrint('✅ [MapProvider] Poll #$_pollAttempts → OK (${stationMap.length} surtidores)');
    }
  } catch (e) {
    _pollErrors++;
    _error = e.toString();
    debugPrint('❌ [MapProvider] Poll #$_pollAttempts → ERROR: $_error');
  }

  _loading = false;
  _pollInProgress = false;
  notifyListeners();
}

/// Convierte PositionPhysicalDto (de YAM) a PositionPhysical (de Flutter)
Map<int, PositionPhysical> _convertToPositionPhysical(
    Map<int, PositionPhysicalDto> source) {
  return source.map((key, dto) => MapEntry(
    key,
    PositionPhysical(
      number: dto.number,
      pumpId: dto.pumpId,
      pumpName: dto.pumpName,
      faceIndex: dto.faceIndex,
      faceLabel: dto.faceLabel,
      faceDescription: dto.faceDescription,
      hoses: dto.hoses.map((h) => HosePhysical(
        nozzleNumber: h.nozzleNumber,
        hoseKey: h.hoseKey,
        fuel: Fuel(name: h.fuel.name, color: h.fuel.colorValue),
        status: h.status,
        dispenserNumber: h.dispenserNumber,
        dispenserKey: h.dispenserKey,
        totalVolume: h.totalVolume,
        totalAmount: h.totalAmount,
      )).toList(),
    ),
  ));
}
```

### Opcion B: Agregar switch para elegir método

```dart
// Flag para elegir entre método viejo y nuevo
static const bool useYamStationMap = true;

Future<void> loadMapDirect() async {
  if (useYamStationMap) {
    await _loadFromYam();
  } else {
    await _loadFromHorustecDirect();
  }
}
```

---

## Paso 5: Limpiar código innecesario (opcional)

Si todo funciona bien, puedes eliminar:

- `PositionBuilder.buildDirect()` - YAM hace esto ahora
- `ApiHelper.getMapHoseDispenser()` - Ya no se necesita para polling
- `ConsoleApiHelper.getDispensersStatus()` - Ya no se usa para polling
- `_cachedMappings` en MapProvider - YAM cachea los mappings

---

## Verificación

1. Compilar YAM y verificar que corre sin errores
2. Probar endpoint con Postman/Insomnia:
   ```
   GET http://TU_IP:8088/api/dispensers/station-map
   ```
3. Verificar respuesta JSON tiene estructura correcta
4. Implementar cambios en Flutter
5. Probar polling en la app

---

## Troubleshooting

### Error: "No se puede conectar a YAM"
- Verificar que YAM está corriendo
- Verificar IP y puerto en `Constans.baseUrlYam`
- Verificar firewall permite conexiones

### Error: "stationMap vacío"
- Verificar que HoseKeyMap tiene datos en la DB
- Verificar que Horustec responde correctamente

### Error: "Timeout"
- YAM puede estar tardando en consultar Horustec
- Aumentar timeout en Flutter o verificar conexión YAM ↔ Horustec
