import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/cierreactivo.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';

import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Providers/map_provider.dart'; // ⬅️ nuevo provider clásico
import 'package:tester/Providers/tranascciones_provider.dart';

import 'package:tester/Providers/usuario_provider.dart';
import 'package:tester/Screens/logIn/login_screen.dart';
import 'package:tester/ViewModels/dispatch_control.dart';



void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CierreActivoProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => TransaccionesProvider()),
        ChangeNotifierProvider(create: (_) => FacturasProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()), 
        ChangeNotifierProvider(create: (_) => DespachosProvider()), // ⬅️ nuevo provider
        ChangeNotifierProvider(
          create: (ctx) => DispatchControl(ctx.read<DespachosProvider>())
            ..onLastUnpaid = (tx) {
              final p = ctx.read<TransaccionesProvider>();
              p.upsert(tx);
              // opcional “carrito” efímero:
              // p.setSelected(tx.id, true);
            },
        ), 
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fuelred Mobile',
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}
