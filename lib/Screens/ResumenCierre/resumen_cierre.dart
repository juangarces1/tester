import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/ResumenCierre/cierre_caja_general.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/response.dart';
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
  final AllFact factura;
  const ResumenCierre({super.key, required this.factura});

  @override
  State<ResumenCierre> createState() => _ResumenCierreState();
}

class _ResumenCierreState extends State<ResumenCierre> {
  CierreCajaGeneral cierre = CierreCajaGeneral();
  bool showLoader = false;
 
  @override
  void initState() {
    getCierre();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar:   MyCustomAppBar(
          title: 'Resumen Cierre',
          automaticallyImplyLeading: true,   
          backgroundColor: kPrimaryColor,
          elevation: 8.0,
          shadowColor: Colors.blueGrey,
          foreColor: Colors.white,
          actions: [ 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipOval(child:  Image.asset(
                    'assets/splash.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),), // Ícono de perfil de usuario
              ),
          ],
       ),
       body: _getContent(),
      )

    );
  }

    Future<void> getCierre() async {

    setState(() {
     
      showLoader = true;
    });   
   
    Response response = await ApiHelper.getCierreActivo(widget.factura.cierreActivo!.cierreFinal.idcierre.toString());
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
         Container(
            color: kContrateFondoOscuro,
           child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                   const SizedBox(height: 15,),
         
                   CardCierre(cierre: widget.factura.cierreActivo!, showButton: false,),
                   const SizedBox(height: 10,),
                   cardResumen(),
         
                    cierre.depositos != null && cierre.depositos!.isNotEmpty ?   CardDepositoCierre(
                      depositos: cierre.depositos!, 
                      baseColor: kPrimaryText, 
                      foreColor: Colors.white
                    ): Container(),
         
                    cierre.facturas != null && cierre.facturas!.isNotEmpty ?   CardFacturasCierre(
                      facturas: cierre.facturas!.where((factura) => factura.plazo != null && factura.plazo! > 0).toList(),
          
                      baseColor: kBlueColorLogo, 
                      foreColor: Colors.white,
                      title: 'Facturas Credito',
                    ): Container(),
         
                     cierre.facturas != null && cierre.facturas!.isNotEmpty ?  CardFacturasCierre(
                      facturas: cierre.facturas!.where((factura) => factura.plazo != null && factura.plazo! == 0).toList(),
          
                      baseColor: const Color.fromARGB(255, 99, 3, 172), 
                      foreColor: Colors.white,
                      title: 'Facturas Contado',
                    ): Container(),
         
                    cierre.transferencias != null && cierre.transferencias!.isNotEmpty ?  CardTransferenciaCierre(
                      transfers: cierre.transferencias!,
          
                      baseColor: const Color.fromARGB(255, 66, 13, 62), 
                      foreColor: Colors.white,
                     
                    ): Container(),
         
                      cierre.calibraciones != null && cierre.calibraciones!.isNotEmpty ?  CardCaliCierre(
                        calibraciones: cierre.calibraciones!,
                        baseColor: const Color.fromARGB(255, 2, 12, 39), 
                        foreColor: Colors.white,
                                      ): Container(),
         
                     cierre.cashbacks != null && cierre.cashbacks!.isNotEmpty ?  CardCashbackCierrre(
                        cashs: cierre.cashbacks!,
                        baseColor: const Color.fromARGB(255, 4, 150, 176), 
                        foreColor: Colors.white,
                                      ): Container(),
                     cierre.cierresDatafono != null && cierre.cierresDatafono!.isNotEmpty ?  CardCierredatafonosCierre(
                        cierredatafonos: cierre.cierresDatafono!,
                        baseColor: const Color.fromARGB(255, 2, 148, 34), 
                        foreColor: Colors.white,
                                      ): Container(),
                     cierre.viaticos != null && cierre.viaticos!.isNotEmpty ?  CardViaticoCierre(
                        viaticos: cierre.viaticos!,
                        baseColor: const Color.fromARGB(255, 46, 4, 28), 
                        foreColor: Colors.white,
                                      ): Container(),
                    cierre.sinpes != null && cierre.sinpes!.isNotEmpty ?  CardSinpecierre(
                        sinpes: cierre.sinpes!,
                        baseColor: const Color.fromARGB(255, 2, 22, 49), 
                        foreColor: Colors.white,
                                      ): Container(),
         
                      cierre.tarjetas != null && cierre.tarjetas!.isNotEmpty ?  CardTarjetasCierre(
                        tarjetas: cierre.tarjetas!,
                        baseColor: const Color.fromARGB(214, 56, 47, 218),
                        foreColor: Colors.white,
                    ) : Container(),                  
                 
                     cierre.peddlers != null && cierre.peddlers!.isNotEmpty ?  CardPeddlerCierre(
                        peddlers: cierre.peddlers!,
                        baseColor: const Color.fromARGB(214, 56, 47, 218),
                        foreColor: Colors.white,
                    ) : Container(),
         
                    cierre.articulosVenta != null && cierre.articulosVenta!.isNotEmpty ?  CardVentasCierre(
                        ventas: cierre.articulosVenta!,
                        baseColor: const Color.fromARGB(213, 234, 115, 18),
                        foreColor: Colors.white,
                    ) : Container(),    
         
                      cierre.inventariofinal != null && cierre.inventariofinal!.isNotEmpty ?  CardinventarioFinalCierre(
                        inventariofinal: cierre.inventariofinal!,
                        baseColor: kPrimaryColor,
                        foreColor: Colors.white,
                      ) : Container(),   

                      CardFinal(cierre: widget.factura.cierreActivo!, showButton: false, precierrePress: () => preCierre(), cierrePress: () => setCierre(), )                                
         
                  ],
                ),
               ),
         ),
         showLoader ? const LoaderComponent(loadingText: 'Cargando...',) : Container(),
       ],
     );

  }

  Future<void> preCierre () async {

    if(widget.factura.cierreActivo!.cajero.cedulaEmpleado != widget.factura.cierreActivo!.usuario.cedulaEmpleado) {
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
   
    Response response = await ApiHelper.preCierre(widget.factura.cierreActivo!.cierreFinal.idcierre.toString());
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

    if(widget.factura.cierreActivo!.cajero != widget.factura.cierreActivo!.usuario) {
       Fluttertoast.showToast(
        msg: "No tiene autorizacion para realizar el Cierre",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      ); 
     
    }

     setState(() {
     
      showLoader = true;
    });   
   
    Response response = await ApiHelper.setCierre(widget.factura.cierreActivo!.cierreFinal.idcierre.toString());
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