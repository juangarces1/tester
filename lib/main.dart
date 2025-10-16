import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Providers/tranascciones_provider.dart';
import 'package:tester/Providers/usuario_provider.dart';
import 'package:tester/Screens/logIn/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CierreActivoProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => TransaccionesProvider()),
        ChangeNotifierProvider(create: (_) => FacturasProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()), // <- una sola vez
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => DespachosProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()),
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
  void initState() {
    super.initState();
    // Enlaza providers y hace bind de la impresora tras montar el árbol:
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final desp = context.read<DespachosProvider>();
      final tran = context.read<TransaccionesProvider>();
      desp.bindTransacciones(tran);

      // Inicializa la impresora (bind al servicio nativo)
     
      // Si quieres, puedes chequear el estado:
      // final ok = context.read<PrinterProvider>().isBound;
      // debugPrint('Printer bound: $ok');
    });
  }

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
