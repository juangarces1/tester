import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/ResumenCierre/cierre_caja_general.dart';

import 'package:tester/Models/FuelRed/cierrefinal.dart';
import 'package:tester/Models/FuelRed/empleado.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_calibracion_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_cashbac_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_cirredatafono_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_depositos.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_facturas_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_final.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_invntario_final_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_peddler_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_sinpes_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_tarjetas_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_transferencias_cierer.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_ventas_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/card_viatico_cierre.dart';
import 'package:tester/Screens/ResumenCierre/Components/depositos_card.dart';
import 'package:tester/Screens/logIn/login_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';

class ResumenCierre extends StatefulWidget {
  
  const ResumenCierre({super.key,});

  @override
  State<ResumenCierre> createState() => _ResumenCierreState();
}

class _ResumenCierreState extends State<ResumenCierre> {
  CierreCajaGeneral cierre = CierreCajaGeneral();
  bool showLoader = false;
  late CierreFinal cierreFinal;
  late Empleado cajero;
  late Empleado usuario;

  /// Paleta curada: variantes tonales (red/pink/wine/orange) con suficiente
  /// contraste entre sí pero manteniendo cohesión cálida. Texto blanco encima
  /// se lee bien en todas.
  static const _paleta = <Color>[
    Color(0xFF991B1B), // red-800
    Color(0xFFB91C1C), // red-700
    Color(0xFFDC2626), // red-600
    Color(0xFF9F1239), // rose-800
    Color(0xFFBE185D), // pink-700
    Color(0xFF86198F), // fuchsia-800
    Color(0xFF6B21A8), // purple-800
    Color(0xFF581C87), // purple-900
    Color(0xFF7C2D12), // orange-900
    Color(0xFFC2410C), // orange-700
    Color(0xFF9A3412), // orange-800
    Color(0xFFB45309), // amber-700
    Color(0xFF854D0E), // amber-800
    Color(0xFF4C1D95), // violet-900
  ];

  Color _variante(int i) => _paleta[i % _paleta.length];

  @override
  void initState() {
    cierreFinal = Provider.of<CierreActivoProvider>(context, listen: false).cierreFinal!;
    cajero = Provider.of<CierreActivoProvider>(context, listen: false).cajero!;
    usuario = Provider.of<CierreActivoProvider>(context, listen: false).usuario!;
    getCierre();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(idCierre: cierreFinal.idcierre ?? 0),
              Expanded(child: _getContent()),
            ],
          ),
        ),
      ),
    );
  }

    Future<void> getCierre() async {

    setState(() {
     
      showLoader = true;
    });   


    Response response = await ApiHelper.getCierreActivo(cierreFinal.idcierre.toString());
    setState(() {
        showLoader = false;
    });
   if (!response.isSuccess) {
        
        if (mounted) {       
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content:  Text(response.message),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Aceptar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }  
       return;
     }  
    
      
     setState(() {
         cierre = response.result;
     });

  }
  
    Widget cardResumen(){
     return Card(
      color: kPrimaryColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
      child: ExpansionTile(
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        title: const Text('Resumen', style: TextStyle(color: Colors.white ,fontWeight: FontWeight.bold,)),
        children: [ 
          cierre.totalDepositosColon > 0 ?   DepositosCustomCard(
            title: 'Colones',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalDepositosColon,
            colorVariable: "aaaadfaaf"
          ): const SizedBox(height: 0,),
     
         cierre.totalDepositosCheque > 0 ?   DepositosCustomCard(
            title: 'Cheques',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalDepositosCheque,
            colorVariable: "gfdsfg"
          ): const SizedBox(height: 0,),
          
           cierre.totalDepositosDollar > 0 ?   DepositosCustomCard(
            title: 'Dolares',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalDepositosDollar,
            colorVariable: "ewrgdsfg"
          ): const SizedBox(height: 0,),

          cierre.totalDepositosCupones > 0 ?   DepositosCustomCard(
            title: 'Cuponees',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalDepositosDollar,
            colorVariable: "hfgwerwer"
          ): const SizedBox(height: 0,),

           cierre.totalDepositosCupones > 0 ?   DepositosCustomCard(
            title: 'Cuponees',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalDepositosDollar,
            colorVariable: "hfgwerwer"
          ): const SizedBox(height: 0,),

          cierre.totalFacturasCredito > 0 ?   DepositosCustomCard(
            title: 'Facturas Credito',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalFacturasCredito,
            colorVariable: "adsfgfr"
          ): const SizedBox(height: 0,),

          cierre.totalMontocashbacks > 0 ?   DepositosCustomCard(
            title: 'Cashbacks',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalMontocashbacks,
            colorVariable: "hdfghertds4354534gadfg"
          ): const SizedBox(height: 0,),

          cierre.totalMontoCalibraciones > 0 ?   DepositosCustomCard(
            title: 'Calibraciones',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalMontoCalibraciones,
            colorVariable: "adsfgfr"
          ): const SizedBox(height: 0,),

          cierre.totalMontotarjetas > 0 ?   DepositosCustomCard(
            title: 'Tarjetas Canje',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalMontotarjetas,
            colorVariable: "ytr465fg"
          ): const SizedBox(height: 0,),
           
          cierre.totalMontoCierresDatafono > 0 ?   DepositosCustomCard(
            title: 'Cierre Datafonos',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalMontoCierresDatafono,
            colorVariable: "ytr465fg"
          ): const SizedBox(height: 0,), 

         cierre.totalMontoTransferencias > 0 ?   DepositosCustomCard(
            title: 'Transferencias',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalMontoTransferencias,
            colorVariable: "fghjsgfgsfhgf"
          ): const SizedBox(height: 0,),  

         cierre.totalMontoViaticos > 0 ?   DepositosCustomCard(
            title: 'Viaticos',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalMontoViaticos,
            colorVariable: "jhgfertert345"
          ): const SizedBox(height: 0,),  

         cierre.totalSinpes > 0 ?   DepositosCustomCard(
            title: 'Sinpes',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalSinpes,
            colorVariable: "gdsfgew343545"
          ): const SizedBox(height: 0,), 

           cierre.totalCierre > 0 ?   DepositosCustomCard(
            title: 'Total Cierre',
            baseColor: kPrimaryColor, 
            foreColor: Colors.white, 
            valor: cierre.totalCierre,
            colorVariable: "aaasdferefd3"
          ): const SizedBox(height: 0,),  
          
            

        ],         
      ),
    );
   }

   _getContent() {
   return
     Stack(
       children: [
         SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                   const SizedBox(height: 15,),
                    
                  const CardCierre( showButton: false,),
                   const SizedBox(height: 10,),
                   cardResumen(),
         
                    // Cada expandible usa una variante del kPrimaryColor
                    // (mismo tono rojo/rosa/naranja/vino, distinta
                    // luminosidad/saturación) para dar jerarquía visual sin
                    // romper la coherencia del palette.
                    if (cierre.depositos?.isNotEmpty ?? false)
                      CardDepositoCierre(
                        depositos: cierre.depositos!,
                        baseColor: _variante(0),
                        foreColor: Colors.white,
                      ),

                    if (cierre.facturas?.isNotEmpty ?? false)
                      CardFacturasCierre(
                        facturas: cierre.facturas!
                            .where((f) => f.plazo != null && f.plazo! > 0)
                            .toList(),
                        baseColor: _variante(1),
                        foreColor: Colors.white,
                        title: 'Facturas Credito',
                      ),

                    if (cierre.facturas?.isNotEmpty ?? false)
                      CardFacturasCierre(
                        facturas: cierre.facturas!
                            .where((f) => f.plazo != null && f.plazo! == 0)
                            .toList(),
                        baseColor: _variante(2),
                        foreColor: Colors.white,
                        title: 'Facturas Contado',
                      ),

                    if (cierre.transferencias?.isNotEmpty ?? false)
                      CardTransferenciaCierre(
                        transfers: cierre.transferencias!,
                        baseColor: _variante(3),
                        foreColor: Colors.white,
                      ),

                    if (cierre.calibraciones?.isNotEmpty ?? false)
                      CardCaliCierre(
                        calibraciones: cierre.calibraciones!,
                        baseColor: _variante(4),
                        foreColor: Colors.white,
                      ),

                    if (cierre.cashbacks?.isNotEmpty ?? false)
                      CardCashbackCierrre(
                        cashs: cierre.cashbacks!,
                        baseColor: _variante(5),
                        foreColor: Colors.white,
                      ),

                    if (cierre.cierresDatafono?.isNotEmpty ?? false)
                      CardCierredatafonosCierre(
                        cierredatafonos: cierre.cierresDatafono!,
                        baseColor: _variante(6),
                        foreColor: Colors.white,
                      ),

                    if (cierre.viaticos?.isNotEmpty ?? false)
                      CardViaticoCierre(
                        viaticos: cierre.viaticos!,
                        baseColor: _variante(7),
                        foreColor: Colors.white,
                      ),

                    if (cierre.sinpes?.isNotEmpty ?? false)
                      CardSinpecierre(
                        sinpes: cierre.sinpes!,
                        baseColor: _variante(8),
                        foreColor: Colors.white,
                      ),

                    if (cierre.tarjetas?.isNotEmpty ?? false)
                      CardTarjetasCierre(
                        tarjetas: cierre.tarjetas!,
                        baseColor: _variante(9),
                        foreColor: Colors.white,
                      ),

                    if (cierre.peddlers?.isNotEmpty ?? false)
                      CardPeddlerCierre(
                        peddlers: cierre.peddlers!,
                        baseColor: _variante(10),
                        foreColor: Colors.white,
                      ),

                    if (cierre.articulosVenta?.isNotEmpty ?? false)
                      CardVentasCierre(
                        ventas: cierre.articulosVenta!,
                        baseColor: _variante(11),
                        foreColor: Colors.white,
                      ),

                    if (cierre.inventariofinal?.isNotEmpty ?? false)
                      CardinventarioFinalCierre(
                        inventariofinal: cierre.inventariofinal!,
                        baseColor: _variante(12),
                        foreColor: Colors.white,
                      ),   

                      CardFinal(
                        showButton: false,
                        estado: cierreFinal.estado,
                        precierrePress: () => preCierre(),
                        cierrePress: () => setCierre(),
                      ),
                      const SizedBox(height: 24),
                  ],
                ),
               ),
         showLoader ? const LoaderComponent(loadingText: 'Cargando...',) : Container(),
       ],
     );

  }

  Future<void> preCierre () async {

    if(cajero.cedulaEmpleado != usuario.cedulaEmpleado) {
       Fluttertoast.showToast(
        msg: "No tiene autorizacion para realizar el Pre Cierre",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      ); 
       return;
    }

     setState(() {
     
      showLoader = true;
    });   
   
    Response response = await ApiHelper.preCierre(cierreFinal.idcierre.toString());
    setState(() {
        showLoader = false;
    });
   if (!response.isSuccess) {
        
        if (mounted) {       
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content:  Text(response.message),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Aceptar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }  
       return;
     }  

      Fluttertoast.showToast(
        msg: "Pre Cierre Creado Correctamente",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
      ); 
     Future.delayed(const Duration(seconds: 2), () {
        // Aquí va el código que quieres que se ejecute después del delay
        goLogin();
      });

     
  }

   Future<void> setCierre () async {

    if (cajero.cedulaEmpleado != usuario.cedulaEmpleado) {
       Fluttertoast.showToast(
        msg: "No tiene autorizacion para realizar el Cierre",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );
       return;
    }

     setState(() {
     
      showLoader = true;
    });   
   
    Response response = await ApiHelper.setCierre(cierreFinal.idcierre.toString());
    setState(() {
        showLoader = false;
    });
   if (!response.isSuccess) {
        
        if (mounted) {       
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content:  Text(response.message),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Aceptar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }  
       return;
     }  

      Fluttertoast.showToast(
        msg: "Cierre Cierre Creado Correctamente",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
      ); 
     Future.delayed(const Duration(seconds: 2), () {
        // Aquí va el código que quieres que se ejecute después del delay
        goLogin();
      });

     
  }
  
  void goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen()
      )
    );
  }
}

/// Header con gradiente (matching form_pago_v2 + transfer/sinpe screens).
class _Header extends StatelessWidget {
  final int idCierre;
  const _Header({required this.idCierre});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 14),
      child: Row(
        children: [
          _GlassBackButton(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de Cierre',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Totales y detalle de movimientos del turno',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'CIERRE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '#$idCierre',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 1),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 22),
        ),
      ),
    );
  }
}