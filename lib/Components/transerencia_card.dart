import 'package:flutter/material.dart';
import 'package:tester/Models/transparcial.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';


class TransferenciaCard extends StatelessWidget {
  final TransParcial transfer;
  const TransferenciaCard({super.key , required this.transfer});

  @override
  Widget build(BuildContext context) {
    return  Card(
                  color: kContrateFondoOscuro,
                   shadowColor: kPrimaryColor,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 88,
                        child: AspectRatio(
                          aspectRatio: 0.80,
                          child: Container(
                            padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                            decoration: const BoxDecoration(
                              color: kContrateFondoOscuro,
                               borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                 bottomLeft: Radius.circular(24))
                            ),
                            child:  const Image(
                                        image: AssetImage('assets/tr9.png'),
                                    ),
                          ),
                        ),
                      ),                         
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                             transfer.cliente.toString(),
                              style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 2,
                            ),
                         
                            Text.rich(
                              TextSpan(
                                 text: 'Aplicado: ${VariosHelpers.formattedToCurrencyValue(transfer.aplicado.toString())}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, color: kPrimaryColor),
                                                          
                              ),
                            ),
                             Text.rich(
                              TextSpan(
                                text: 'Deposito #:${transfer.numeroDeposito}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, color: Colors.black54),
                                                          
                              ),
                            ),
                             Text.rich(
                              TextSpan(
                                  text: 'Saldo: ${VariosHelpers.formattedToCurrencyValue(transfer.saldo.toString())}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, color: kBlueColorLogo),
                                                          
                              ),
                            )                                
                          ],
                        ),
                      )                
                    ],
                  ),
                );
  }
}