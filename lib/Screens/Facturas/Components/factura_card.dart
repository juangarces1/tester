import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';

class FacturaCard extends StatelessWidget {
     final Factura factura;
      final int index;
      final VoidCallback onInfoPressed;
      final VoidCallback onPrintPressed;
      final VoidCallback onConfirmPressed;
     const FacturaCard({
    super.key,
       required this.factura,
       required this.index,
       required this.onInfoPressed,
       required this.onPrintPressed,
       required this.onConfirmPressed,
  });
       

    
    @override
    Widget build(BuildContext context) {
      return Card(
        shadowColor: const Color.fromARGB(255, 0, 2, 3),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 204, 202, 219),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          factura.isFactura
                              ? const Text(
                                  'Factura Electrónica',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColor,
                                  ),
                                )
                              : factura.isTicket
                                  ? const Text(
                                      'Ticket Electrónico',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryColor,
                                      ),
                                    )
                                  : factura.isDevolucion
                                      ? const Text(
                                          'Nota de Credito',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimaryColor,
                                          ),
                                        )
                                      : const SizedBox(height: 0,),
                          factura.isTicket == false
                              ? Text(
                                 textAlign: TextAlign.center,
                                  factura.cliente,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: kBlueColorLogo,
                                  ),
                                )
                              : const SizedBox(height: 0,),
                          const SizedBox(height: 5,),
                          Text(
                            'Numero: ${factura.nFactura}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kTextColorBlack,
                            ),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Fecha: ${VariosHelpers.formatYYYYmmDD(factura.fechaHoraTrans)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextColorBlack,
                            ),
                          ),
                          const SizedBox(height: 5,),
                           Text(
                            'Hora: ${VariosHelpers.formatToHour(factura.fechaHoraTrans)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextColorBlack,
                            ),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Productos: ${factura.detalles.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kTextColorBlack,
                            ),
                          ),
                          const SizedBox(height: 5,),
                          Text(
                            'Total: ${VariosHelpers.formattedToCurrencyValue(factura.totalFactura.toString())}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 5,),
                          Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: MaterialButton(
                                    onPressed: onInfoPressed,
                                    color: kBlueColorLogo,
                                    padding: const EdgeInsets.all(5),
                                    shape: const CircleBorder(),
                                    child: const Icon(
                                      Icons.list_outlined,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: MaterialButton(
                                    onPressed: onPrintPressed,
                                    color: Colors.blueGrey,
                                    padding: const EdgeInsets.all(5),
                                    shape: const CircleBorder(),
                                    child: const Icon(
                                      Icons.print_outlined,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            factura.isDevolucion ? Container() :  Flexible(
                                  child: MaterialButton(
                                    onPressed: onConfirmPressed,
                                    color: kPrimaryColor,
                                    padding: const EdgeInsets.all(5),
                                    shape: const CircleBorder(),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
}