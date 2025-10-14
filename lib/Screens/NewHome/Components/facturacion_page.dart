import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/no_contetnt.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/show_process.dart';
import 'package:tester/Screens/Peddlers/peddlers_add_screen.dart';
import 'package:tester/Screens/checkout/checkount.dart';
import 'package:tester/Screens/credito/credit_process_screen.dart';
import 'package:tester/Screens/tickets/ticket_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

class FacturacionPage extends StatelessWidget {
  const FacturacionPage({
    super.key,    
  });

  

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 36, 37, 37),
          ),
          child: _gridFacturacion(context),
        ),
        Positioned(
          bottom: 15,
          left: 15,
          child: SizedBox(
            height: 56,
            width: 56,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShowProcessMenu(),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/AddTr.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 15,
          right: 15,
          child: SizedBox(
            height: 56,
            width: 56,
            child: GestureDetector(
              onTap: () => _mostrarMenu(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/backToCheck.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gridFacturacion(BuildContext context) {
    return Consumer<FacturasProvider>(
      builder: (context, facturasProvider, child) {
        return facturasProvider.facturas.isNotEmpty
            ? Container(
                color: const Color.fromARGB(255, 39, 40, 41),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: facturasProvider.facturas.length,
                    itemBuilder: (context, index) {
                      return _crearTarjetaFactura(context, facturasProvider.facturas[index]);
                    },
                  ),
                ),
              )
            : Container(
                color: const Color.fromARGB(255, 34, 35, 36),
                child: const MyNoContent(
                  text: 'No hay Facturas...',
                  backgroundColor: Colors.black45,
                  borderColor: Colors.black,
                  borderWidth: 0.5,
                ),
              );
      },
    );
  }

  Widget _crearTarjetaFactura(BuildContext context, Invoice facturaActual) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(getProportionateScreenWidth(10)),
          decoration: BoxDecoration(
            color: VariosHelpers.getShadedColor(
              facturaActual.total.toString(),
              kColorFondoOscuro,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          width: getProportionateScreenWidth(170),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                facturaActual.tipoInvoice,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(20),
                  fontWeight: FontWeight.bold,
                  color: facturaActual.isPromo!
                      ? Colors.black
                      : facturaActual.isContado!
                          ? Colors.orange
                          : facturaActual.isTicket!
                              ? Colors.green
                              : facturaActual.isCredit!
                                  ? Colors.blue
                                  : Colors.yellow,
                ),
              ),
              const SizedBox(height: 11),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Material(
                    color: VariosHelpers.getShadedColor(
                      facturaActual.total.toString(),
                      kColorFondoOscuro,
                    ),
                    child: Ink.image(
                      image: AssetImage(
                        facturaActual.isContado!
                            ? 'assets/factura.png'
                            : facturaActual.isTicket!
                                ? 'assets/Ticket.png'
                                : facturaActual.isCredit!
                                    ? 'assets/Cred1.png'
                                    : facturaActual.isPeddler!
                                        ? 'assets/peddler.png'
                                        : 'assets/factura.png',
                      ),
                      fit: BoxFit.cover,
                      child: InkWell(
                        onTap: () => _navegarSegunTipoInvoice(context, facturaActual),
                      ),
                    ),
                  ),
                ),
              ),
              facturaActual.isTicket!
                  ? Container()
                  : Text(
                      facturaActual.isCredit!
                          ? facturaActual.formPago!.clienteCredito.obtenerPrimerNombre()
                          : facturaActual.isPeddler!
                              ? facturaActual.formPago!.clienteCredito.obtenerPrimerNombre()
                              : facturaActual.isContado!
                                  ? facturaActual.formPago!.clienteFactura.obtenerPrimerNombre()
                                  : 'hey',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(16),
                        fontWeight: FontWeight.normal,
                        color: kColorMenu,
                      ),
                    ),
              Text(
                VariosHelpers.formattedToCurrencyValue(facturaActual.total.toString()),
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarFactura(context, facturaActual),
              tooltip: 'Eliminar Factura',
            ),
          ),
        ),
      ],
    );
  }

  void _navegarSegunTipoInvoice(BuildContext context, Invoice invoice) {
    final facturasProvider = Provider.of<FacturasProvider>(context, listen: false);
    final index = facturasProvider.facturas.indexOf(invoice);

    if (invoice.isCredit == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProceeeCreditScreen(index: index)),
      );
    } else if (invoice.isPeddler == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PeddlersAddScreen(index: index)),
      );
    } else if (invoice.isContado == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CheaOutScreen(index: index)),
      );
    } else if (invoice.isTicket == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TicketScreen(index: index)),
      );
    }
  }

  void _eliminarFactura(BuildContext context, Invoice facturaActual) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar'),
          content: Text('¿Estás seguro de que quieres eliminar ${facturaActual.tipoInvoice}?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Eliminar'),
              onPressed: () {
                FacturaService.eliminarFactura(context, facturaActual);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarMenu(BuildContext context) {

   
    final cierreActivo = Provider.of<CierreActivoProvider>(context, listen: false);
    final nuevaFactura = Invoice.createInitializedInvoice(cierreActivo.cierreFinal, cierreActivo.usuario);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'Elige una opción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _crearBotonOpcion(context, 'Contado', nuevaFactura, kPrimaryColor),
                _crearBotonOpcion(context, 'Ticket', nuevaFactura, Colors.green),
                _crearBotonOpcion(context, 'Credito', nuevaFactura, kBlueColorLogo),
                _crearBotonOpcion(
                  context,
                  'Peddler',
                  nuevaFactura,
                  const Color.fromARGB(255, 196, 177, 5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _crearBotonOpcion(
    BuildContext context,
    String texto,
    Invoice invoice,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(context).pop();

          final facturasProvider = Provider.of<FacturasProvider>(context, listen: false);

          final index = facturasProvider.addInvoice(invoice);

          if (texto == 'Contado') {
            invoice.isContado = true;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CheaOutScreen(index: index)),
            );
          } else if (texto == 'Ticket') {
            invoice.isTicket = true;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => TicketScreen(index: index)),
            );
          } else if (texto == 'Credito') {
            invoice.isCredit = true;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => ProceeeCreditScreen(index: index)),
            );
          } else if (texto == 'Peddler') {
            invoice.isPeddler = true;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PeddlersAddScreen(index: index)),
            );
          }
        },
      ),
    );
  }
}
