import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/boton_flotante.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/show_client_credito.dart';
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
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';


class ProceeeCreditScreen extends StatefulWidget {
 final int index; 
  // ignore: use_key_in_widget_constructors
  const ProceeeCreditScreen({   
    required this.index,   
   });
  @override
  State<ProceeeCreditScreen> createState() => _ProceeeCreditScreen();
}

class _ProceeeCreditScreen extends State<ProceeeCreditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showLoader = false;
  bool placaTypeIdShowError =false;
  String placaTypeIdError ='';
  String placa = ''; 
   late TextEditingController kms;
  late TextEditingController obser;
  final String _codigoError = '';
  final bool _codigoShowError = false; 
  late Invoice factura;
 
    @override
  void initState() {
    super.initState();
    // Obtener la factura inicial sin escuchar cambios
    factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    kms = TextEditingController(text: factura.kms.toString());
    obser = TextEditingController(text: factura.observaciones.toString());
   
  }

   @override
  void dispose() {
    kms.dispose();
    obser.dispose();
   super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
       Invoice facturaC = Provider.of<FacturasProvider>(context).getInvoiceByIndex(widget.index);

    return SafeArea(
      child: Scaffold(
        backgroundColor: kContrateFondoOscuro,
        appBar:  PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: appBar1(facturaC),
        ),
        body: _body(facturaC),
        floatingActionButton:  FloatingButtonWithModal(index: widget.index,),
          resizeToAvoidBottomInset: false, 
      ),
    );
  }

   Widget appBar1(Invoice facturaApp) {
   return SafeArea(    
      child: Container(
        color: const Color.fromARGB(247, 16, 40, 86),
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
                  onPressed: (){
                    FacturaService.updateFactura(context, facturaApp);
                    Navigator.pop(context);
                  },           
                  child: SvgPicture.asset(
                    "assets/Back ICon.svg",
                    height: 15,
                    // ignore: deprecated_member_use
                    color: const Color.fromARGB(255, 11, 30, 53),
                  ),
                ),
              ),
              const SizedBox(width: 10,),            
              const Text.rich(
                TextSpan(
                  text: "Factura Credito",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:kNewtextPri,
                  ),
                ),
              ),
              const Spacer(),
              Container(
               
                
              )
            ],
          ),
        ),
      ),
    );
 } 


  Widget _body(Invoice facturaC) {     
    return Container(
      color: kNewbg,
      child: Stack(
        children: [ SizedBox(
            width: double.infinity,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                      ShowClientCredito(
                        index: widget.index,                       
                        padding: const EdgeInsets.only(left: 0.0, right: 0),
                      ),
                   facturaC.formPago!.clienteCredito.nombre!.isNotEmpty ?     ShowEmail(email: facturaC.formPago!.clienteCredito.email!) : Container(),
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                  //  SelectClienteCredito(factura: widget.factura, ruta: 'Credito',),
                    signUpForm(),  
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                    showTotal(facturaC), 
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
             
          _showLoader ? const LoaderComponent(loadingText: 'Creando...') : Container(),
        ],
      ),
    );
  }

    void onItemSelected (Product product) {
      setState(() {
        factura.detail!.add(product);
      });
  }
 
  Widget signUpForm() {
     return Form(
      key: _formKey,
      child: Column(
        children: [
         showkms(),         
         showPlaca(), 
         showObser(), 
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getComboPlacas() {
    List<DropdownMenuItem<String>> list = [];

    list.add(const DropdownMenuItem(
      value: '',
      child: Text('Seleccione una Placa...'),
    ));

     for (var placa in factura.formPago!.clienteCredito.placas!) {
       list.add(DropdownMenuItem(
         value: placa.toString(),
         child: Text(placa.toString()),
       ));
     }

    return list;
  }

  Widget showkms() {
  return Container(
    padding: const EdgeInsets.all(10),
    child: TextField(
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
      ],
      decoration: darkDecoration(
        label: 'Kms',
        hint: 'Ingresa los kms',
        errorText: _codigoShowError ? _codigoError : null,
        suffixIcon:  const Icon(Icons.car_repair_rounded, color: kNewtextSec),
         enabledBorder: darkBorder(color: Colors.blue),
        focusedBorder: darkBorder(color: Colors.blue, width: 1.8),
        errorBorder: darkBorder(color: Colors.blue, width: 1.8),
        focusedErrorBorder: darkBorder(color: Colors.blue, width: 1.8),
       ),
      style: const TextStyle(color: kNewtextPri),
      cursorColor: Colors.blue,
            onChanged: (value) {
              kms.text = value; // tu lógica intacta
      },
    ),
  );
}

Widget showObser() {
  return Container(
    padding: const EdgeInsets.all(10),
    child: TextField(
      controller: obser,
      keyboardType: TextInputType.text,
      maxLines: 3,
      style: const TextStyle(color: kNewtextPri),
      cursorColor: Colors.blue,
      decoration: darkDecoration(
        label: 'Observaciones',
        hint: 'Ingrese las Observaciones',
        enabledBorder: darkBorder(color: Colors.blue),
        focusedBorder: darkBorder(color: Colors.blue, width: 1.8),
        errorBorder: darkBorder(color: Colors.blue, width: 1.8),
        focusedErrorBorder: darkBorder(color: Colors.blue, width: 1.8),
        suffixIcon: const Icon(Icons.sms_outlined, color: kNewtextSec),
      ),
    ),
  );
}



  Widget showPlaca() {
  return Container(
    padding: const EdgeInsets.all(10),
    child: DropdownButtonFormField<String>(
      items: _getComboPlacas(),    // asegúrate de que los Text de los items usen style: TextStyle(color: _textPri)
      value: placa,
      style: const TextStyle(color: kNewtextPri, fontSize: 16), // texto seleccionado
      dropdownColor: kNewsurface,   // fondo del menú
      iconEnabledColor: kNewtextSec,
      iconDisabledColor: kNewtextMut,
      menuMaxHeight: 320,
      onChanged: (option) {
        setState(() {
          placa = option as String;
        });
      },
      decoration: darkDecoration(
        label: 'Placas',
        hint: 'Seleccione una Placa...',
        errorText: placaTypeIdShowError ? placaTypeIdError : null,
        fillColor: kNewsurface, // más plano en dropdowns
        enabledBorder: darkBorder(),                 // <- puedes pasar bordes aquí
        focusedBorder: darkBorder(color: Colors.blue, width: 1.8),
        errorBorder: darkBorder(color: Colors.blue, width: 1.8),
      ),
    ),
     
    );
  }


  Widget showTotal(Invoice facturaC) {
 return SafeArea(
  child: Padding(
    padding:
        EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
    child:
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(           
            
            TextSpan(
              
              text: "Total:\n",
                style: const TextStyle(fontSize: 22, color: kNewtextPri, fontWeight: FontWeight.bold ),
              children: [
                TextSpan(
                  text: " ${VariosHelpers.formattedToCurrencyValue(facturaC.total.toString())}",
                  style: const TextStyle(fontSize: 22, color: kNewtextPri, fontWeight: FontWeight.bold ),
                ),
              ],
            ),
          ),
        
            factura.detail!.isNotEmpty && factura.formPago!.clienteCredito.nombre!.isNotEmpty ? 
                        SizedBox(
                           width: getProportionateScreenWidth(150),
                          child: DefaultButton(
                          text: "Facturar",
                          press: () => _goFact(), 
                          gradient: kBlueGradient,  
                          color: kBlueColorLogo,           
                          ),
                        )                
                        : Container(),
        ],
      ),
    ),
  );
}

 Future<void> _goFact()  async{
 
 
    setState(() {
      _showLoader = true;
    });      
      if (kms.text=='') {
        kms.text='0';
      }
      Map<String, dynamic> request = 
      {
        'products': factura.detail!.map((e) => e.toApiProducJson()).toList(),
        'idCierre' : factura.cierre!.idcierre,
        'cedualaUsuario' : factura.empleado!.cedulaEmpleado.toString(),
        'cedulaClienteFactura' : factura.formPago!.clienteCredito.documento,
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
        'clientePaid' : factura.formPago!.clienteCredito.toJson(),
        'Transferencia' : factura.formPago!.transfer.toJson(),
        'kms':kms.text,
        'observaciones' :obser.text,
        'placa':placa     

      };
      Response response = await ApiHelper.post("Api/Facturacion/CreditFactura", request);  

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
    //  factura.actualizarCantidadProductos();
   //   factura.resetFactura();

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
      
    //   testPrint.printFactura(resdocFactura, 'FACTURA', 'CREDITO');
    //   testPrint.printFactura(resdocFactura, 'FACTURA', 'CREDITO');
      _goHomeSuccess();
  }



  Future<void> _goHomeSuccess() async {  
     FacturaService.eliminarFactura(context, factura);
     Navigator.pop(context);     
    }

 
}