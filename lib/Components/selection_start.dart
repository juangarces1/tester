import 'package:flutter/material.dart';

import '../constans.dart';

class FuelPosition {
  final String nombre;
  final bool disponible;

  FuelPosition(this.nombre, this.disponible);
}

// Supón que recibes esta lista desde la API
Future<List<FuelPosition>> fetchFuelPositionsFromApi() async {
  // Simula petición; aquí deberías consumir la API real con http o Dio.
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    FuelPosition("Super", true),
    FuelPosition("Regular", true),
    FuelPosition("Diesel", false), // No disponible
    FuelPosition("Exonerado", true),
  ];
}

class SelectFuelCardScreen extends StatefulWidget {
  final String sideName;
  final String estado;
  final void Function(String nombreCombustible)? onSelect;

  const SelectFuelCardScreen({
    super.key,
    required this.sideName,
    required this.estado,
    this.onSelect,
  });

  @override
  State<SelectFuelCardScreen> createState() => _SelectFuelCardScreenState();
}

class _SelectFuelCardScreenState extends State<SelectFuelCardScreen> {
  late Future<List<FuelPosition>> futurePositions;

  @override
  void initState() {
    super.initState();
    futurePositions = fetchFuelPositionsFromApi(); // <-- aquí conectas tu API real
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[950],
      appBar: AppBar(
        title: Text('Playa ${widget.sideName}'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle,
                    color: widget.estado == "OK"
                        ? Colors.greenAccent
                        : Colors.amber,
                    size: 18),
                const SizedBox(width: 8),
                Text("Estado actual: ${widget.estado}",
                    style: TextStyle(color: Colors.grey[200], fontSize: 15)),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Seleccione el combustible:",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Widget asíncrono de la lista de posiciones
            FutureBuilder<List<FuelPosition>>(
              future: futurePositions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text("Error al cargar posiciones",
                      style: TextStyle(color: Colors.red));
                }
                final opciones = snapshot.data!;
                return Column(
                  children: opciones
                      .map((opt) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              onTap: opt.disponible
                                  ? () => widget.onSelect?.call(opt.nombre)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Card(
                                color: opt.disponible
                                    ? getFuelColor(opt.nombre).withValues(alpha: 0.13)
                                    : Colors.grey[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: opt.disponible
                                        ? getFuelColor(opt.nombre)
                                        : Colors.grey[700]!,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_gas_station,
                                        color: opt.disponible
                                            ? getFuelColor(opt.nombre)
                                            : Colors.grey,
                                        size: 34,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        opt.nombre,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: opt.disponible
                                              ? Colors.white
                                              : Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (!opt.disponible)
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(left: 16),
                                          child: Icon(Icons.block,
                                              color: Colors.grey, size: 22),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}



// --------- Color según nombre de combustible ----------
Color getFuelColor(String nombre) {
  switch (nombre.toLowerCase()) {
    case 'super':
      return kSuperColor;
    case 'regular':
      return kRegularColor;
    case 'diesel':
      return kDieselColor;
    case 'exonerado':
      return kExoColor;
    default:
      return Colors.grey;
  }
}