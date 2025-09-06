import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Screens/test_print/testprint.dart';


import 'package:tester/constans.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  // final BluePrintPos bluetooth = BluePrintPos.instance;
  // List<BlueDevice> _devices = [];
  // BlueDevice? _device;
  final bool _connected = false;
  bool showLoading = false;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() => showLoading = true);

    try {
      // final devices = await bluetooth.scan();  
      // // :contentReference[oaicite:0]{index=0}
      // setState(() {
      //   _devices = devices;
      //   showLoading = false;
      // });
    } on PlatformException {
      setState(() => showLoading = false);
      _showSnack('Error al escanear dispositivos');
    }
  }

  Future<void> _connect() async {
    // if (_device == null) {
    //   _showSnack('Seleccione un dispositivo');
    //   return;
    // }
    setState(() => showLoading = true);
  //  final status = await bluetooth.connect(_device!);
    // ConnectionStatus.connected, disconnect, timeout…
    setState(() {
      // _connected = status == ConnectionStatus.connected;
      // showLoading = false;
    });
  }

  Future<void> _disconnect() async {
    // setState(() => showLoading = true);
    // final status = await bluetooth.disconnect();
    // setState(() {
    //   _connected = status == ConnectionStatus.disconnect;
    //   showLoading = false;
    // });
  }

  void _showSnack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyCustomAppBar(
          title: 'Impresora Bluetooth',
          elevation: 6,
          shadowColor: kColorFondoOscuro,
          automaticallyImplyLeading: true,
          foreColor: Colors.white,
          backgroundColor: kBlueColorLogo,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipOval(
                child: Image.asset('assets/splash.png', width: 30, height: 30, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              ListView(
                children: [
                  const Row(
                    children: [
                      Text('Dispositivo:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 20),
                      // Expanded(
                      //   child: DropdownButton<BlueDevice>(
                      //       isExpanded: true,
                      //       items: _devices.map((d) => DropdownMenuItem(
                      //         value: d,
                      //         child: Text(d.name ?? '—'),
                      //       )).toList(),
                      //       value: context.watch<PrinterProvider>().device,
                      //       onChanged: (d) => context.read<PrinterProvider>().device = d,
                      //     ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _scanDevices,
                        child: const Text('Actualizar'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _connected ? Colors.red : Colors.green,
                        ),
                        onPressed: _connected ? _disconnect : _connect,
                        child: Text(_connected ? 'Desconectar' : 'Conectar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // ElevatedButton(
                  //   style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                  //   onPressed: _connected
                  //       // ? () => TestPrint(device: _device!).sample()
                  //       // : () => _showSnack('Conecta primero'),
                  //   child: const Text('Imprimir Prueba', style: TextStyle(color: Colors.white)),
                  // ),
                ],
              ),
              if (showLoading)
                const Center(child: LoaderComponent(loadingText: 'Procesando…')),
            ],
          ),
        ),
      ),
    );
  }
}
