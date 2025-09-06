
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/client_card.dart';
import 'package:tester/Components/color_button.dart';
import 'package:tester/Components/custom_surfix_icon.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';


class ClientesFrecScreen extends StatefulWidget {
  final Invoice factura; 
  final String ruta;


  // ignore: use_key_in_widget_constructors
  const ClientesFrecScreen({   
    required this.factura,   
    required this.ruta,
   });
  @override
  State<ClientesFrecScreen> createState() => _ClientesFrecScreen();
}

class _ClientesFrecScreen extends State<ClientesFrecScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showLoader = false;  
 
 
  
  var docuemntController = TextEditingController();

  String _documentError = '';
  bool _documentShowError = false;
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kContrateFondoOscuro,
        appBar: MyCustomAppBar(
          title: 'Buscar Cliente Frecuente',
          elevation: 6,
          shadowColor: kColorFondoOscuro,
          automaticallyImplyLeading: true,
          foreColor: Colors.white,
          backgroundColor: kPrimaryColor,
          actions: <Widget>[
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
        body: _body(),
      ),
    );
  }

  Widget _body() {     
    return Container(
      color: kContrateFondoOscuro,
      child: SafeArea(
        child: Stack(
          children:[
            SizedBox(
            width: double.infinity,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // SizedBox(height: SizeConfig.screenHeight * 0.04), // 4%
                    // Text("Digite Codigo Cliente", style: headingStyle),                
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                    signUpForm(),             
                    
                  ],
                ),
              ),
            ),
          ),
           _showLoader ? const LoaderComponent(loadingText: 'Buscando...') : Container(),
          ]
        ),
      ),
    );
  }

  Widget signUpForm() {

     return Form(
      key: _formKey,
      child: Column(
        children: [
          showDocument(),   
          const SizedBox(height: 10),       
          ColorButton(
            text: "Buscar",
            press: _getClient,
            ancho: 100,
            color: kPrimaryColor,
          ),
          SizedBox(height: SizeConfig.screenHeight * 0.04),

          widget.factura.formPago!.clientePuntos.nombre.isEmpty ? Container() 
          : ClientCard(client: widget.factura.formPago!.clientePuntos,),
        
                  
           widget.factura.formPago!.clientePuntos.nombre.isEmpty ? Container() 
          :  SizedBox(
            width: getProportionateScreenWidth(120),
            child: DefaultButton(
               text: 'Select',
               press: () => _goCheckOut(),
               gradient: kPrimaryGradientColor, 
               color: kPrimaryColor,))
         
        ],
      ),
    );
  }
 
  Widget showDocument() {
    return Container(
           
           padding: const EdgeInsets.all(15),
           decoration: BoxDecoration(
             color: kContrateFondoOscuro,
             borderRadius: BorderRadius.circular(20)
           ),
          child: TextField( 
            maxLength: 7,       
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            decoration: InputDecoration(
              hintText: 'Ingresa el codigo',
              labelText: 'Codigo Cliente',
              errorText: _documentShowError ? _documentError : null,             
              suffixIcon: const CustomSurffixIcon(svgIcon: "assets/receipt.svg"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            onChanged: (value) {
              docuemntController.text = value;
            },
          ),
        );
 }


  Future<void> _getClient() async {
   
    if(!_validateFields()) {
      return;
    }
    
    setState(() {
      _showLoader=true;
    });

    
    Response response = await ApiHelper.getClientFrec(docuemntController.text);  

    setState(() {
      _showLoader = false;
    });

    if(!response.isSuccess){  
     
      Fluttertoast.showToast(
          msg: "No Encontrado",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        );   
       
      return;
    }      
   
    setState(() {
      widget.factura.formPago!.clientePuntos = response.result;
     
    }); 

  }
    
 

  bool _validateFields() {
    bool isValid = true;  

     if (docuemntController.text.isEmpty){
        _documentShowError=true;
        _documentError="Debes Ingresar un Documento";
        isValid=false;
    } else if (docuemntController.text.length != 7 ) {      
      _documentShowError = true;
      _documentError = 'Debes ingresar un codigo de 7 carácteres.';
       isValid=false;
    } else {
      _documentShowError=false;
    }  

    

    setState(() { });
    return isValid;
  }

 

  void _goCheckOut() async {
     FacturaService.updateFactura(context, widget.factura);                  
     Navigator.pop(context);


  }
}