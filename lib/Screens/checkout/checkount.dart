import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/boton_flotante.dart';
import 'package:tester/Components/client_points.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/form_pago.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/show_client.dart';
import 'package:tester/Components/show_email.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/factura.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/boton_combustibles.dart';
import 'package:tester/Screens/NewHome/Components/produccts_page.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';



// ignore: must_be_immutable
class CheaOutScreen extends StatefulWidget {
  final int index; 
  
  // ignore: use_key_in_widget_constructors
  const CheaOutScreen({ 
    required this.index,   
  }); 

  @override
  State<CheaOutScreen> createState() => _CheaOutScreenState();
}



class _CheaOutScreenState extends State<CheaOutScreen> { 
  
  bool _showLoader = false;
  late TextEditingController kms;
  late TextEditingController obser;
  late TextEditingController placa;  
  late Invoice factura;
  final GlobalKey<FormPagoState> formPagoKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  
  
 
  void callGoRefresh() {
    formPagoKey.currentState?.goRefresh();
  }
 
   @override
  void initState() {
    super.initState();
    // Obtener la factura inicial sin escuchar cambios
    factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    kms = TextEditingController(text: factura.kms.toString());
    obser = TextEditingController(text: factura.observaciones.toString());
    placa = TextEditingController(text: factura.placa.toString());
  }

   @override
  void dispose() {
    kms.dispose();
    obser.dispose();
    placa.dispose();
 

    super.dispose();
  }

     
  @override
  Widget build(BuildContext context) {
     Invoice facturaC = Provider.of<FacturasProvider>(context, listen: true).getInvoiceByIndex(widget.index);

    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: appBar1(facturaC),
        ),
        body: Container(
          color: kNewborder,
          child: Stack(
            children: <Widget>[
              RefreshIndicator(
                onRefresh: () async {
                  callGoRefresh();
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child:  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[                  
                           const SizedBox(height: 15,),
                         ClientPoints(factura: facturaC, ruta: 'Contado'), 
                        const SizedBox(height: 15,),
                         FormPago(
                            key: formPagoKey,
                            index: widget.index,
                            fontColor: kNewtextPri,
                          
                            ruta: 'Contado',
                           ),
                                    
                         const SizedBox(height: 20,), 
                        signUpForm(),   
                          const SizedBox(height: 5,),  
                          factura.detail!.isNotEmpty  && factura.saldo == 0 && factura.formPago!.clienteFactura.nombre.isNotEmpty ? 
                          Padding(
                            padding: const EdgeInsets.only(left: 50.0, right: 50, bottom: 15),
                            child: DefaultButton(
                            text: "Facturar",
                            press: () => goFact(facturaC), 
                            gradient: kPrimaryGradientColor, 
                            color: kPrimaryColor,            
                            ),
                          )                
                          : Container(),
                           const SizedBox(height: 60,),  
                      ],
                    ),
                  ),
                ),
              ),     

              Positioned(
                bottom: 15,
                left: 80,                      
                child: SizedBox(
                  height: 56,
                  width: 56,
                  child: GestureDetector(
                      onTap: () =>  Navigator.push
                         (context,
                             MaterialPageRoute(
                               builder: (context) =>
                                 ProductsPage(
                                   index: widget.index,                 
                                  )
                             )
                         ),
                      child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), // Borde semicurvo para la imagen
                  child: Image.asset(
                    'assets/Aceite1.png',
                    fit: BoxFit.fill, // Ajusta la imagen para que llene el contenedor
                  ),
                        ),
                  ),
                ),
              ),
              
               Positioned(
                bottom: 15,
                left: 10,                      
                child: BotonTransacciones(
                  imagePath: 'assets/AddTr.png',
                    onItemSelected: onItemSelected, 
                    zona: facturaC.cierre!.idzona! )
                ),
              
              _showLoader ? const LoaderComponent(loadingText: "Creando Factura...") : Container(),  

              
            ],
          ),
        ),
        floatingActionButton: FloatingButtonWithModal(index: widget.index,)
      ),
    );    
  }

   void onItemSelected (Product product) {
      setState(() {
        factura.detail!.add(product);
      });
  }

  Widget signUpForm() {
     return Container(
      decoration: BoxDecoration(
        color: kNewsurfaceHi,
        border: Border.all(color: kNewtextPri, width: 1),
        borderRadius: BorderRadius.circular(10)),
       child: ExpansionTile(
        backgroundColor: kNewsurfaceHi,
         title: const Text(
            'Información de la Factura',
            style: TextStyle(
              color: kNewtextPri,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        iconColor: kNewtextPri,
        collapsedIconColor: kNewtextPri,
           
         children: [
           Container( 
              padding: const EdgeInsets.only(top: 15),            
             decoration: BoxDecoration(
                color:kNewsurfaceHi,
                 gradient: const LinearGradient(
                   colors: [kPrimaryColor, Color.fromARGB(255, 255, 255, 255)],
                   begin: Alignment.centerRight,
                   end:  Alignment(0.95, 0.0),
                   tileMode: TileMode.clamp),
               border: Border.all(
               color: kSecondaryColor,
                           width: 1,
               ),
             ),
             child: Column(
               children: [
                 
                const SizedBox(height: 10,),
           
                 ShowClient(
                  factura: factura,
                   ruta: 'Contado',
                   padding: const EdgeInsets.only(left: 40.0, right: 40),
                ),
                 factura.formPago!.clienteFactura.nombre.isNotEmpty ?  
                    Padding(
                      padding: const EdgeInsets.only(left: 40, right: 40),
                      child: ShowEmail(email: factura.formPago!.clienteFactura.email, backgroundColor: kColorFondoOscuro,),
                    ) : Container(),
                  const SizedBox(height: 15,),
                 showkms(),
                 const SizedBox(height: 15,),
                 showPlaca(),
                 const SizedBox(height: 15,),
                 showObser(), 
                 const SizedBox(height: 15,), 
                    
               ],
             ),
           ),
         ],
       ),
     );
  }

  Widget showkms() {
    return Container(
           padding: const EdgeInsets.only(left: 50.0, right: 50),
          child: TextField(  
            controller: kms,           
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            decoration: const InputDecoration(
              hintText: 'Ingrese los kms',
              labelText: 'Kms',                         
              suffixIcon: Icon(Icons.car_repair_rounded),           
            ),
             onChanged: (value) {            
            if (value.isNotEmpty){ 
              setState(() {    
                factura.kms = int.parse(value);
                FacturaService.updateFactura(context, factura);                                   

              });  
            }         
          },         
            
          ),
        );
 }
 
  Widget showObser() {
    return Container(
        padding: const EdgeInsets.only(left: 50.0, right: 50),
        child: TextField(
        controller: obser,      
        keyboardType: TextInputType.text,            
        decoration: const InputDecoration(             
          labelText: 'Observaciones', 
            hintText: 'Ingrese las Observaciones',                        
          suffixIcon:  Icon(Icons.sms_outlined), 
        
        ),
        onChanged: (value) {            
            if (value.isNotEmpty){ 
              setState(() {    
                factura.observaciones = (value);
                FacturaService.updateFactura(context, factura);                                   

              });  
            }         
          },            
        ),
      );
 }

  Widget showPlaca() {
    return Container(
          padding: const EdgeInsets.only(left: 50.0, right: 50),
          child: TextField(
            controller: placa,      
            keyboardType: TextInputType.text,            
            decoration: const InputDecoration(             
              labelText: 'Placa',      
               hintText: 'Ingrese la Placa',                      
              suffixIcon:  Icon(Icons.sms_outlined), 
            
            ),
              onChanged: (value) {            
            if (value.isNotEmpty){ 
              setState(() {    
                factura.placa = (value);
                FacturaService.updateFactura(context, factura);                                   

              });  
            }         
          },          
          ),
        );
 }
  
  Widget appBar1(Invoice facturaApp) {
   return Container(
     color: kNewredPressed,
     child: Padding(
       padding:
           EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
       child: Row(  
          mainAxisAlignment: MainAxisAlignment.spaceBetween,              
         children: [
           SizedBox(
             height: getProportionateScreenHeight(45),
             width: getProportionateScreenWidth(45),
             child: TextButton(
               style: TextButton.styleFrom(
                 shape: RoundedRectangleBorder(     
                   borderRadius: BorderRadius.circular(60),
                 ),
                 backgroundColor: kNewtextPri,
                 padding: EdgeInsets.zero,
               ),
               onPressed: (){
                 FacturaService.updateFactura(context, facturaApp);
                 Navigator.pop(context);
               },           
               child: SvgPicture.asset(
                 "assets/Back ICon.svg",
                 height: 15,
                 // ignore: deprecated_member_use
                 color:Colors.black,
               ),
             ),
           ),
           const SizedBox(width: 10,),            
          //  
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kNewred.withOpacity(.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kContrateFondoOscuro, width: 1),
            ),
            child: const Text(
              "CONTADO",
              style: TextStyle(
                color: kNewtextPri,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              
              ),
            ),
          ),
           const Spacer(),
           Container(
            
             padding: const EdgeInsets.only(top: 8, right: 5),
             decoration: BoxDecoration(
              
               borderRadius: BorderRadius.circular(14),
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
               children: [
                 Text(
                   "Total:${NumberFormat("###,###", "en_US").format(facturaApp.total.toInt())}",
                   style: const TextStyle(
                     color: kNewtextPri,
                     fontSize: 20,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
                 const SizedBox(width: 3),
                 Text(
                   "Saldo:${NumberFormat("###,###", "en_US").format(facturaApp.saldo)}",
                   style: const TextStyle(
                     color: kNewtextPri,
                     fontSize: 20,
                     fontWeight: FontWeight.w600,
                   ),
                 ),                 
               ],
             ),
           )
         ],
       ),
     ),
   );
 } 

  Future<void> goFact(Invoice facturaApp) async {
    if(factura.saldo!=0) {
      Fluttertoast.showToast(
            msg: "La factura aun tiene saldo.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color.fromARGB(255, 70, 19, 15),
            textColor: Colors.white,
            fontSize: 16.0
          );      
      return;
    }
 
    setState(() {
      _showLoader = true;
    });    
           
      Map<String, dynamic> request = 
      {
        'products': facturaApp.detail!.map((e) => e.toApiProducJson()).toList(),
        'idCierre' : facturaApp.cierre!.idcierre,
        'cedualaUsuario' : facturaApp.empleado!.cedulaEmpleado.toString(),
        'cedulaClienteFactura' : facturaApp.formPago!.clienteFactura.documento,
        'totalEfectivo' : facturaApp.formPago!.totalEfectivo,        
        'totalBac' : facturaApp.formPago!.totalBac,
        'totalDav' : facturaApp.formPago!.totalDav,
        'totalBn' : facturaApp.formPago!.totalBn,
        'totalSctia' : facturaApp.formPago!.totalSctia,
        'totalSinpe' : facturaApp.formPago!.totalSinpe,
        'totalDollars' : facturaApp.formPago!.totalDollars,
        'totalCheques' : facturaApp.formPago!.totalCheques,
        'totalCupones' : facturaApp.formPago!.totalCupones,
        'totalPuntos' : facturaApp.formPago!.totalPuntos,
        'totalTransfer' : facturaApp.formPago!.totalTransfer,
        'saldo' : facturaApp.saldo,
        'clientePaid' : facturaApp.formPago!.clientePuntos.toJson(),
        'Transferencia' : facturaApp.formPago!.transfer.toJson(), 
        'kms': kms.text.isEmpty ? '0' : kms.text,       
        'placa': placa.text.isEmpty ? '' : placa.text,  
        'sinpe': facturaApp.formPago!.sinpe.toJson(),
        'observaciones' : obser.text.isEmpty ? '' : obser.text,
      };
     
      Response response = await ApiHelper.post("Api/Facturacion/PostFactura", request);  
    
      setState(() {
       _showLoader = false;
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
   
      
      var decodedJson = jsonDecode(response.result);
      Factura resdocFactura = Factura.fromJson(decodedJson);   
      resdocFactura.usuario = factura.empleado!.nombreCompleto;
    

      String cl =   factura.formPago!.clientePuntos.nombre;
      double pCanje = factura.formPago!.totalPuntos;
      int pAcu = factura.formPago!.clientePuntos.puntos;
    //   final printerProv = context.read<PrinterProvider>();
    //     final device = printerProv.device;
    //     if (device == null) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text('Selecciona antes un dispositivo')),
    //       );
    //       return;
    //     }

    //     final testPrint = TestPrint(device: device);
    //  //Cheaqueamos si hay puntos para canjear y si es asi imprimimos el canje
    //   if(factura.formPago!.totalPuntos > 0) {
        
    //       testPrint.printPuntosCanje(
    //           cl,
    //           resdocFactura.usuario!, 
    //           pAcu,
    //           resdocFactura.nFactura,
    //           pCanje,
    //         );
    //    }
    //    else {
    //     //Si no hay puntos  Cheaqueamos si hay puntos para acumular y si es asi imprimimos el acumulo
    //     List<Product> pds = factura.buscarAcumulacion();
    //      if(pds.isNotEmpty) {
    //        testPrint.printPuntosAcumulados(
    //           cl,
    //           resdocFactura.usuario!,
    //           resdocFactura.nFactura,
    //           pds,
    //         );
    //      }   
    //    }
          
    //   if(factura.formPago!.totalTransfer > 0) {
    //     testPrint.printTransferencia(      
                
    //           factura.formPago!.transfer,
    //             resdocFactura.usuario!,
    //         );
    //   }

    //    if(factura.formPago!.totalSinpe > 0) {
    //     testPrint.printSinpe(      
                
    //           factura.formPago!.sinpe,
    //             resdocFactura.usuario!,
    //         );
    //   }
 
    //   // ask the user if wants to print the factura
    //    if (mounted) {
    //       showDialog(
    //         context: context,
    //         builder: (BuildContext context) {
    //           return AlertDialog(
    //             title: const Text('Factura Creada Exitosamente'),
    //             content:  const Text('Desea imprimir la factura?'),
    //             actions: <Widget>[
    //               TextButton(
    //                 child: const Text('Si'),
    //                 onPressed: () {
    //                   Navigator.of(context).pop();
    //                   testPrint.printFactura(resdocFactura,'FACTURA','CONTADO');
    //                   _goHomeSuccess(facturaApp);
    //                 },
    //               ),
    //               TextButton(
    //                 child: const Text('No'),
    //                 onPressed: () {
    //                    Navigator.of(context).pop();
    //                     _goHomeSuccess(facturaApp);
    //                 },
    //               ),
    //             ],
    //           );
    //         },
    //       );
    //     } 

    

    _goHomeSuccess(facturaApp);
  }

   Future<void> _goHomeSuccess(Invoice facturaC) async {
    FacturaService.eliminarFactura(context, facturaC);
    Navigator.pop(context);
      
 }
  

}



