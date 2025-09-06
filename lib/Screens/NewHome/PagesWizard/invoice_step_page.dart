// lib/Screens/Dispatch/invoice_step_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Screens/NewHome/Components/menu_page.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/Screens/NewHome/PagesWizard/hose_step_page.dart';

class InvoiceStepPage extends StatelessWidget {
  final String dispatchId;
  const InvoiceStepPage({required this.dispatchId, super.key});

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<DespachosProvider>(context, listen: false);
    final dispatch = despachosProv.getById(dispatchId)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('2. Tipo de Factura', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
         actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ir al menú',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MenuPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: InvoiceType.values.map((type) {
              // Definimos colores según el tipo
              Color background;
              Color foreground;
              switch (type) {
                case InvoiceType.contado:
                  background = Colors.red;
                  foreground = Colors.white;
                  break;
                case InvoiceType.credito:
                  background = Colors.blue;
                  foreground = Colors.white;
                  break;
                case InvoiceType.peddler:
                  background = Colors.yellow;
                  foreground = Colors.black;
                  break;
                case InvoiceType.ticket:
                  background = Colors.green;
                  foreground = Colors.white;
                  break;
              }
        
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: background,
                    foregroundColor: foreground,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    dispatch.invoiceType = type;
                     despachosProv.refresh();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HoseStepPage(dispatchId: dispatchId),
                      ),
                    );
                  },
                  child: Text(
                    type.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: foreground,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
