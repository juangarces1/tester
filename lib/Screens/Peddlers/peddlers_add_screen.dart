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
import 'package:tester/Models/peddler.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/boton_combustibles.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';




class PeddlersAddScreen extends StatefulWidget {
  final int index;
 
  // ignore: use_key_in_widget_constructors
  const PeddlersAddScreen({   
    required this.index,
   
    
   });

  @override
  State<PeddlersAddScreen> createState() => _PeddlersAddScreenState();
}

class _PeddlersAddScreenState extends State<PeddlersAddScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showLoader = false; 
  bool placaTypeIdShowError =false;
  var placaTypeIdError ='';
  String placa = ''; 
 
  late TextEditingController kms;
  late TextEditingController obser;
  late TextEditingController ch;
  late TextEditingController or;

  bool chShowError=false;
  String chError="";
  bool obserShowError=false;
  String obserError="";
  bool orShowError=false;
  String orError="";
  bool kmShowError=false;
  String kmError="";
   late Invoice factura;
   final ScrollController _scrollController = ScrollController();
  final FocusNode _kmsFocusNode = FocusNode();
  final FocusNode _choferFocusNode = FocusNode();
  final FocusNode _ordenFocusNode = FocusNode();
  final FocusNode _observacionesFocusNode = FocusNode(); 

  @override
  void initState() {
    super.initState();
    // Obtener la factura inicial sin escuchar cambios
    factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    kms = TextEditingController(text: factura.peddler!.km.toString());
    obser = TextEditingController(text: factura.peddler!.observaciones.toString());
    ch = TextEditingController(text: factura.peddler!.chofer.toString());
    or = TextEditingController(text: factura.peddler!.orden.toString());
    _kmsFocusNode.addListener(() => _scrollToAvoidKeyboard(_kmsFocusNode));
    _choferFocusNode.addListener(() => _scrollToAvoidKeyboard(_choferFocusNode));
    _ordenFocusNode.addListener(() => _scrollToAvoidKeyboard(_ordenFocusNode));
    _observacionesFocusNode.addListener(() => _scrollToAvoidKeyboard(_observacionesFocusNode));
   
  }

  @override
  void dispose() {
    kms.dispose();
    obser.dispose();
    ch.dispose();
    or.dispose();
    _scrollController.dispose();
    _kmsFocusNode.dispose();
    _choferFocusNode.dispose();
    _ordenFocusNode.dispose();
    _observacionesFocusNode.dispose();
   super.dispose();
  }

  void _scrollToAvoidKeyboard(FocusNode focusNode) {
    if (focusNode.hasFocus) {
      // Obtenemos la altura del teclado inmediatamente
      double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      keyboardHeight += 100;
      // Obtenemos la posición del TextField en la pantalla
      RenderBox renderBox = focusNode.context!.findRenderObject() as RenderBox;
      double textFieldPosition = renderBox.localToGlobal(Offset.zero).dy + renderBox.size.height;

      // Obtenemos la altura de la pantalla
      double screenHeight = MediaQuery.of(context).size.height;

      // Calculamos cuántos píxeles mover para que el TextField esté completamente visible
      double offset = textFieldPosition - (screenHeight - keyboardHeight);

      // Si el TextField está cubierto por el teclado, lo desplazamos
      if (offset > 0) {
        _scrollController.animateTo(
          _scrollController.offset + offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
     Invoice facturaC = Provider.of<FacturasProvider>(context).getInvoiceByIndex(widget.index);

     return SafeArea(
        
       child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: kContrateFondoOscuro,
     //    resizeToAvoidBottomInset: false, 
         appBar:  PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: appBar1(facturaC),
        ),
         body: _body(facturaC),
         floatingActionButton: const FloatingButtonWithModal(index: 0,)
       ),
     ); 
  }

  Widget appBar1(Invoice facturaApp) {
   return SafeArea(    
      child: Container(
        color: kNewsurfaceHi,
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
                   
                   
                    backgroundColor:kNewtextPri,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: (){
                    FacturaService.updateFactura(context, facturaApp);
                    Navigator.pop(context);
                  },           
                  child: SvgPicture.asset(
                    "assets/Back ICon.svg",
                    height: 18,
                    // ignore: deprecated_member_use
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10,),            
              const Text.rich(
                TextSpan(
                  text: "Orden Peddler",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:kTextColorWhite,
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
        color: kNewborder,
       child: Stack(
         children: [ Padding(
           padding:
               EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
           child: SingleChildScrollView(
            controller: _scrollController,
             child: Padding(
               padding: const EdgeInsets.all(5),
               child: Column(
                 children: [
                                
                   SizedBox(height: SizeConfig.screenHeight * 0.02),
                    ShowClientCredito(
                      index: widget.index,                       
                      padding: const EdgeInsets.only(left: 0.0, right: 0),
                    ),
                    facturaC.formPago!.clienteCredito.nombre!.isNotEmpty ? 
                    ShowEmail(email: facturaC.formPago!.clienteCredito.email!)
                    : Container(),
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                    signUpForm(facturaC),  
                     SizedBox(height: SizeConfig.screenHeight * 0.04),
                   showTotal(facturaC),       
                    const SizedBox(height: 150),
                 ],
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
  

   Widget signUpForm(Invoice facturaC) {
      return Form(
       key: _formKey,
       child: Column(
         children: [
          
           showPlaca(facturaC), 
           showkms(facturaC),   
           showOrden(facturaC),
           showChofer(facturaC), 
           showObser(facturaC),         
          
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

   bool _validateFields() {
     bool isValid = true;  
     if (ch.text.isEmpty)
     {
         chShowError=true;
         chError="Debes Ingresar el nombre";
         isValid=false;        
     } 
      else {
       chShowError=false;
     }  
  
     if (kms.text.isEmpty)
     {
         kmShowError=true;
         kmError="Debes Ingresar el kilometraje";
         isValid=false;        
     } 
      else {
       kmShowError=false;
     } 
     if (or.text.isEmpty)
     {
         orShowError=true;
         orError="Debes Ingresar el numero de orden";
         isValid=false;        
     } 
      else {
       orShowError=false;
     } 
     if (placa.isEmpty)
     {
         placaTypeIdShowError=true;
         placaTypeIdError="Debes Seleccionar la placa";
         isValid=false;        
     } 
      else {
       placaTypeIdShowError=false;
     }  
 
     setState(() { });
     return isValid;
   }

     Widget showPlaca(Invoice facturaC) {
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
            focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
            errorBorder: darkBorder(color: Colors.amber, width: 1.8),
          ),
        ),
        
    );
  }
 
   Widget showkms(Invoice facturaC) {
     return Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
           child: TextField(     
            focusNode: _kmsFocusNode,      
             keyboardType: TextInputType.number,
             inputFormatters: <TextInputFormatter>[
               FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
             ],
            decoration: darkDecoration(
                label: 'Kms',
                hint: 'Ingresa los kms',              
                suffixIcon:  const Icon(Icons.car_repair_rounded, color: kNewtextSec),
                enabledBorder: darkBorder(color: Colors.amber),
                focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
                errorBorder: darkBorder(color: Colors.amber, width: 1.8),
                focusedErrorBorder: darkBorder(color: Colors.amber, width: 1.8),
              ),
              style: const TextStyle(color: kNewtextPri),
              cursorColor: Colors.amber,
             onChanged: (value) {
               kms.text = value;
               facturaC.peddler!.km = value;
             },
           ),
         );
  }
 
   Widget showObser(Invoice facturaC) {
     return Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
           child: TextFormField(
            focusNode: _observacionesFocusNode,
             controller: obser,      
             keyboardType: TextInputType.text,            
            
             decoration: darkDecoration(
                label: 'Ingresa las Observaciones...',
                hint: 'Observaciones',
              
                suffixIcon:  const Icon(Icons.car_repair_rounded, color: kNewtextSec),
                enabledBorder: darkBorder(color: Colors.amber),
                focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
                errorBorder: darkBorder(color: Colors.amber, width: 1.8),
                focusedErrorBorder: darkBorder(color: Colors.amber, width: 1.8),
              ),
              style: const TextStyle(color: kNewtextPri),
              cursorColor: Colors.amber,
               onChanged: (value) {
               obser.text = value;
               facturaC.peddler!.observaciones = value;
             },
           ),
         );
  }
 
   Widget showChofer(Invoice facturaC) {
   return Container(
    padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
     child: TextField(
       focusNode: _choferFocusNode,
       controller: ch,      
       keyboardType: TextInputType.text,            
      
         decoration: darkDecoration(
                label: 'Ingresa el Nombre...',
                hint: 'Chofer',
              
                suffixIcon:  const Icon(Icons.car_repair_rounded, color: kNewtextSec),
                enabledBorder: darkBorder(color: Colors.amber),
                focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
                errorBorder: darkBorder(color: Colors.amber, width: 1.8),
                focusedErrorBorder: darkBorder(color: Colors.amber, width: 1.8),
              ),
              style: const TextStyle(color: kNewtextPri),
              cursorColor: Colors.amber, 

        onChanged: (value) {
               ch.text = value;
               facturaC.peddler!.chofer = value;
             },  
     ),
   );
  }
 
   Widget showOrden (Invoice facturaC) {
   return Container(
   padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
     child: TextField(
       focusNode: _ordenFocusNode,
       controller: or,      
       keyboardType: TextInputType.text,            
      
        decoration: darkDecoration(
                label: 'Ingresa el Numero...',
                hint: 'Orden',
              
                suffixIcon:  const Icon(Icons.car_repair_rounded, color: kNewtextSec),
                enabledBorder: darkBorder(color: Colors.amber),
                focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
                errorBorder: darkBorder(color: Colors.amber, width: 1.8),
                focusedErrorBorder: darkBorder(color: Colors.amber, width: 1.8),
              ),
              style: const TextStyle(color: kNewtextPri),
              cursorColor: Colors.amber, 
        onChanged: (value) {
               or.text = value;
               facturaC.peddler!.orden = value;
             },
    
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
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
               children: [
                 TextSpan(
                    text: " ${VariosHelpers.formattedToCurrencyValue(facturaC.total.toString())}",
                   style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                 ),
               ],
             ),
           ),
           facturaC.formPago!.clienteCredito.nombre!.isNotEmpty && facturaC.detail!.isNotEmpty
         ?    SizedBox(
             width: getProportionateScreenWidth(160),
             child: DefaultButton(
               text: "Crear Orden",
               press: () => _goPeddler(factura),
               color: Colors.amber,
               gradient: kYellowGradient,
                textColor: Colors.black,
             ),
           ) : Container(),
         ],
       ),
     ),
   );
 }
   Future<void> _goPeddler(Invoice facturaC) async{
     if(!_validateFields()){
       return;
     }
     setState(() {
       _showLoader=true;
     });

     

      Peddler pd = Peddler(
        id: 0,
        products: facturaC.detail!,
        idcierre:  facturaC.cierre!.idcierre,
        pistero: facturaC.empleado!,
        cliente: facturaC.formPago!.clienteCredito,
        placa: facturaC.peddler!.placa,
        km: facturaC.peddler!.km,
        observaciones: facturaC.peddler!.observaciones,
        chofer: facturaC.peddler!.chofer,
        orden: facturaC.peddler!.orden,
      );
    
     Response response = await ApiHelper.post('Api/Peddler/PostPeddler', pd.toJson());
  
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
    
     if (mounted) {
         showDialog(
           context: context,
           builder: (BuildContext context) {
             return AlertDialog(
               title: const Text('Peddler Creado Exitosamente'),
               content:  const Text('Desea imprimir el Peddler?'),
               actions: <Widget>[
                 TextButton(
                   child: const Text('Si'),
                   onPressed: () {
                  //   Navigator.of(context).pop();

                  //   final printerProv = context.read<PrinterProvider>();
                  //   final device = printerProv.device;
                  //   if (device == null) {
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       const SnackBar(content: Text('Selecciona antes un dispositivo')),
                  //     );
                  //     return;
                  //   }

                  //  // Llamas a tu clase de impresión
                  //   final testPrint = TestPrint(device: device);
                  //   testPrint.printPeddler(pd);
                  //   testPrint.printPeddler(pd);
                  //   // Impresion.printPeddler(request, context);
                  //    _goHomeSuccess();
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
  
   Future<void> _goHomeSuccess() async {  
    
       FacturaService.eliminarFactura(context, factura);
        Navigator.pop(context);   
     }
     
  

}
