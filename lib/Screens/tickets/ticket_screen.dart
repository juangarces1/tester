import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/boton_flotante.dart';
import 'package:tester/Components/client_points.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/form_pago.dart';
import 'package:tester/Components/loader_component.dart';
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
class TicketScreen extends StatefulWidget {
  final int index; 

   // ignore: use_key_in_widget_constructors
  const TicketScreen({ 
    required this.index,   
 
  }); 

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {  
  bool _showLoader =false;
  bool medioShowError = false;
  String mediodError ='';
  late TextEditingController obser;
  late Invoice factura;
  
  final double _saldo = 0;
  final GlobalKey<FormPagoState> formPagoKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  

  void callGoRefresh() {
    formPagoKey.currentState?.goRefresh();
  }

  @override
  void initState() {
    super.initState();
      factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
      obser = TextEditingController(text: factura.observaciones.toString()); 
  } 
   
   @override
   Widget build(BuildContext context) {
      Invoice facturaC = Provider.of<FacturasProvider>(context).getInvoiceByIndex(widget.index);

    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),
          child: appBar1(),
        ),
        body: Container(
          color: kColorFondoOscuro,
          child: Stack(
            children: <Widget>[
              RefreshIndicator(
                onRefresh: () async {
                  callGoRefresh();
                },
                child: SingleChildScrollView(
                   controller: _scrollController,
                  child:  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        ruta: 'Ticket',
                      ),                                  
                         const SizedBox(height: 15,), 
                         signUpForm(), 
                         const SizedBox(height: 15,),  
                          factura.detail!.isNotEmpty  && factura.saldo == 0  ? 
                          Padding(
                            padding: const EdgeInsets.only(left: 50.0, right: 50, bottom: 15),
                            child:  DefaultButton(
                            text: "Facturar",
                            press: () => goTicket(), 
                            color:const Color.fromARGB(255, 17, 50, 19), 
                            gradient: kGreenGradient,
                                         
                            ),
                          )                
                          : Container(),
                           const SizedBox(height: 80,),  
                        
                     
                      ],
                    ),
                  ),
                ),
              ),     
              Positioned(
                bottom: 15,
                left: 80,                      
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductsPage(index: widget.index)
                    )
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10), // Borde semicurvo para la imagen
                    child: SizedBox(
                      height: 56,
                      width: 56,
                      child: Image.asset(
                        'assets/Aceite1.png',
                        // Ajusta la imagen para cubrir el contenedor manteniendo proporciones
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
               _showLoader ? const LoaderComponent(loadingText: "Creando Ticket...") : Container(),     
            ],
          ),
        ),
        floatingActionButton: const FloatingButtonWithModal(index: 0,),
      ),
    );    
  }

  void onItemSelected (Product product) {
    setState(() {
        factura.detail!.add(product);
      });
  }
  

  Future<void> goTicket() async {
    
    if(factura.saldo!=0) {
      Fluttertoast.showToast(
            msg: "La factura aun tiene saldo.",
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
      _showLoader = true;
    });       
      
    Map<String, dynamic> request = 
    {
      'products': factura.detail!.map((e) => e.toApiProducJson()).toList(),
      'idCierre' : factura.cierre!.idcierre,
      'cedualaUsuario' : factura.empleado!.cedulaEmpleado.toString(),
      'cedulaClienteFactura' : factura.formPago!.clienteFactura.documento,
      'totalEfectivo' : factura.formPago!.totalEfectivo,        
      'totalBac' : factura.formPago!.totalBac,
      'totalDav' : factura.formPago!.totalDav,
      'totalBn' : factura.formPago!.totalBn,
      'totalSctia' : factura.formPago!.totalSctia,
      'totalDollars' : factura.formPago!.totalDollars,
      'totalCheques' : factura.formPago!.totalCheques,
      'totalCupones' : factura.formPago!.totalCupones,
      'totalPuntos' : factura.formPago!.totalPuntos,
      'totalTransfer' : factura.formPago!.totalTransfer,
      'saldo' : factura.saldo,
      'clientePaid' : factura.formPago!.clientePuntos.toJson(),
      'Transferencia' : factura.formPago!.transfer.toJson(),
      'observaciones' : obser.text.isEmpty ? '' : obser.text,
      'ticketMedioPago': 'Efectivo',
      'placa':'',      

    };
    Response response = await ApiHelper.post("Api/Facturacion/Ticket", request);  

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
   
      factura.resetFactura();
      // ask the user if wants to print the factura
       if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Ticket Creado Exitosamente'),
                content:  const Text('Desea imprimir el Ticket?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Si'),
                    onPressed: () {
                      Navigator.of(context).pop();
                     // Impresion.printFactura(resdocFactura, 'CONTADO', 'TICKET');
                      // final printerProv = context.read<PrinterProvider>();
                      // final device = printerProv.device;
                      // if (device == null) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(content: Text('Selecciona antes un dispositivo')),
                      //   );
                      //   return;
                      // }

                    // // Llamas a tu clase de impresión
                    // final testPrint = TestPrint(device: device);  
                    //  testPrint.printFactura(resdocFactura, 'TICKET', 'CONTADO');
                      _goHomeSuccess();
                    },
                  ),
                  TextButton(
                    child: const Text('No'),
                    onPressed: () {
                        Navigator.of(context).pop();
                         _goHomeSuccess();
                    },
                  ),
                ],
              );
            },
          );
        } 
  }
 
  Widget appBar1() {
   return SafeArea(    
      child: Container(
        color:const Color.fromARGB(255, 53, 130, 55),
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
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                     FacturaService.updateFactura(context, factura);                  
                     Navigator.pop(context);
                  },      
                  child: SvgPicture.asset(
                    "assets/Back ICon.svg",
                    height: 15,
                    // ignore: deprecated_member_use
                    color: const Color.fromARGB(255, 17, 50, 19),
                  ),
                ),
              ),
               const SizedBox(width: 10,),
              const Text('Ticket', style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:kNewtextPri, 
              ),),
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
                      "Total:${NumberFormat("###,000", "en_US").format(factura.total.toInt())}",
                      style: const TextStyle(
                        color: kNewtextPri,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "Saldo:${NumberFormat("###,000", "en_US").format(_saldo)}",
                      style: const TextStyle(
                        color:kNewtextPri, 
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
      ),
    );
 } 

 
  Widget showObser() {
    return Container(
           padding: const EdgeInsets.only(left: 10.0, right: 10),
          child: TextField(
            controller: obser,      
            keyboardType: TextInputType.text,  
            maxLines: 2,
            style: const TextStyle(color: kNewtextPri, fontSize: 19),
              cursorColor: Colors.green,          
            decoration:  darkDecoration(
                label: 'Observaciones',
                hint: 'Ingrese las Observaciones',
                enabledBorder: darkBorder(color: Colors.green),
                focusedBorder: darkBorder(color: Colors.green, width: 1.8),
                errorBorder: darkBorder(color: Colors.green, width: 1.8),
                focusedErrorBorder: darkBorder(color: Colors.green, width: 1.8),
                suffixIcon: const Icon(Icons.sms_outlined, color: kNewtextSec),
              ),
            
          ),
        );
 }

  Widget signUpForm() {
     return Container( 
        padding: const EdgeInsets.only(top: 15),            
       decoration: const BoxDecoration(
          color: kNewborder,
          
       
       ),
       child: Column(
         children: [
          
            const Text(
           'Información Ticket',
           style: TextStyle(
             color:kNewtextPri,
             fontWeight: FontWeight.bold,
             fontSize: 18,
           ),
        ),
            const SizedBox(height: 15,), 
           showObser(), 
           const SizedBox(height: 15,), 
          
         ],
       ),
     );
  }
 


  Future<void> _goHomeSuccess() async {  
    FacturaService.eliminarFactura(context, factura);
    Navigator.pop(context); 
    }
    


  
}