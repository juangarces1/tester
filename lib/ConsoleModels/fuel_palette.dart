// lib/ui/fuel_palette.dart
import 'package:flutter/material.dart';

class FuelInfo {
  final String name;
  final IconData icon;
  final Color color;
  const FuelInfo(this.name, this.icon, this.color);
}

// Paleta fija solicitada:
// 1 → lila, 2 → rojo, 3 → verde, 5 → azul, otros → amarillo
const _kLila     = Color(0xFF9C27B0); // lila
const _kRojo     = Color(0xFFF44336); // rojo
const _kVerde    = Color(0xFF4CAF50); // verde
const _kAzul     = Color(0xFF2196F3); // azul
const _kAmarillo = Color(0xFFFFC107); // amarillo (fallback)

const FuelInfo _kDefaultFuel = FuelInfo('Otro', Icons.local_gas_station, _kAmarillo);

// Si prefieres nombres específicos, cámbialos aquí.
const Map<int, FuelInfo> kFuelCatalog = {
  1: FuelInfo('Super', Icons.local_gas_station, _kLila),
  2: FuelInfo('Regular', Icons.local_gas_station, _kRojo),
  3: FuelInfo('Diesel', Icons.local_gas_station, _kVerde),
  4: FuelInfo('Exonerado', Icons.local_gas_station, _kAzul),
};

FuelInfo fuelFor(int fuelCode) => kFuelCatalog[fuelCode] ?? _kDefaultFuel;

Color fuelColor(int fuelCode) => fuelFor(fuelCode).color;
String fuelName(int fuelCode)  => fuelFor(fuelCode).name;
IconData fuelIcon(int fuelCode)=> fuelFor(fuelCode).icon;
