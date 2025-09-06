import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:intl/intl.dart';
import 'package:tester/Models/transferfull.dart';
import 'package:tester/constans.dart';

class CardTransfer extends StatefulWidget {
  final TransferFull transfer;
  final bool showDetail;
  const CardTransfer({super.key, required this.transfer, required this.showDetail});

  @override
  State<CardTransfer> createState() => _CardTransferState();
}

class _CardTransferState extends State<CardTransfer> {
  @override
  Widget build(BuildContext context) {
    return Padding(
            padding: const EdgeInsets.only(right: 5, left: 5),
            child: Card(
                color:  Colors.white,
                shadowColor: const Color.fromARGB(255, 147, 192, 224),
                elevation: 7,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
              child: InkWell(
                onTap: () => goDetails1(widget.transfer),
                child: Container(
                  margin: const EdgeInsets.all(5),
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [                    
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.transfer.cliente!, 
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryColor
                                      ),
                                    ),

                                     Text(
                                      'Fecha: ${widget.transfer.fecha}', 
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87
                                      ),
                                    ),
                                 
                                    Text(
                                      'Deposito #: ${widget.transfer.numeroDeposito}', 
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87
                                      ),
                                    ),
                                  
                                    Text(
                                     'Monto: ¢ ${NumberFormat("###,000", "en_US").format(widget.transfer.monto)}', 
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                         color: kBlueColorLogo
                                      ),
                                    ),
                                 
                                    Text(
                                        'Saldo: ¢ ${NumberFormat("###,000", "en_US").format(widget.transfer.saldo)}', 
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                         color: kPrimaryText
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  goDetails1(TransferFull e) {    
    if(widget.showDetail){    
      if(e.descuentos!.isEmpty){
         Fluttertoast.showToast(
            msg: "No hay descuentos registrados.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor:kBlueColorLogo,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
          return;
      }

      // Navigator.push(
      // context, 
      // MaterialPageRoute(
      //   builder: (context) =>  DetailTransferScreen(transfer: e,)
      // )
      // );
    }
  }
}