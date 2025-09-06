

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/client_card.dart';
import 'package:tester/Components/color_button.dart';
import 'package:tester/Components/custom_surfix_icon.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/helpers/api_helper.dart';

import '../../constans.dart';
import '../../sizeconfig.dart';

class ClietesAddScreen extends StatefulWidget {
  final Invoice factura;
  final String ruta; 
  
  const ClietesAddScreen({ 
    super.key, 
    required this.factura,
    required this.ruta,
    
  
  });
   
  @override
  State<ClietesAddScreen> createState() => _ClietesAddScreenState();
}

class _ClietesAddScreenState extends State<ClietesAddScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showLoader = false;  
  Cliente _cliente = Cliente(
    nombre: "",
    documento: "",
    codigoTipoID: "",
    email: "",
    puntos: 0,
     codigo: '',
     telefono: '',
  );

  String _emailError = '';
  bool _emailShowError = false;
  final _telefono = TextEditingController(); 
  String _telefonoError = '';
  bool _telefonoShowError = false; 
  String _documentError = '';
  bool _documentShowError = false;
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: kPrimaryColor,
          title: const Text("Nuevo Cliente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),),
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
        body: _body(),
      ),
    );
  }

  Widget _body() {     
    return SafeArea(
      child: Stack(
        children: [ SizedBox(
          width: double.infinity,
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: SizeConfig.screenHeight * 0.04), // 4%
                  Text("Consultar Cliente", style: myHeadingStyleBlack),
                  const Text(
                    "desde la BD de Hacienda.",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: SizeConfig.screenHeight * 0.03),
                  signUpForm(),
                  SizedBox(height: SizeConfig.screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ),
         _showLoader ? const LoaderComponent(loadingText: 'Consultando...') : Container(),
        ]
      ),
    );
  }

  Widget signUpForm() {
     return Form(
      key: _formKey,
      child: Column(
        children: [
          showDocument(),
          SizedBox(height: getProportionateScreenHeight(10)),
          ColorButton(
            text: "Buscar Cliente",
            press: _getClient,
            ancho: 150,
            color: kPrimaryColor,
          ),
         
          SizedBox(height: getProportionateScreenHeight(10)),
         _cliente.nombre.isNotEmpty ? ClientCard(client: _cliente) : Container(),
          SizedBox(height: getProportionateScreenHeight(30)),
          _cliente.nombre.isNotEmpty ?   Text(
                    "Complete los Datos",
                    style: myHeadingStyleBlack,
                    textAlign: TextAlign.center,
                  ):Container(),
        _cliente.nombre.isNotEmpty ?  _showEmail() : Container(),         
          SizedBox(height: getProportionateScreenHeight(10)),
           _cliente.nombre.isNotEmpty ?  showPhone() : Container(),         
          SizedBox(height: getProportionateScreenHeight(10)),
        _cliente.nombre.isNotEmpty ?  DefaultButton(
            text: "Crear",
            press: _createClient,
            color: kPrimaryColor,
            gradient: kPrimaryGradientColor,
          ): Container(),
        ],
      ),
    );
  }
 
  Widget showDocument() {
    return Container(
          padding: const EdgeInsets.all(10),
          child: TextField(        
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ingresa un Documento...',
              labelText: 'Documento',
              errorText: _documentShowError ? _documentError : null,             
              suffixIcon: const CustomSurffixIcon(svgIcon: "assets/receipt.svg"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            onChanged: (value) {
              _cliente.documento = value;
            },
          ),
        );
 }

  Widget showPhone() {
    return Container(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _telefono,      
            keyboardType: TextInputType.number,
            
            decoration: InputDecoration(             
              labelText: 'Telefono',
              errorText: _telefonoShowError ? _telefonoError : null,             
              suffixIcon: const CustomSurffixIcon(svgIcon: 'assets/User.svg'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            onChanged: (value) {
              _cliente.telefono = value;
            },
          ),
        );
 }

  Widget _showEmail() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: TextField(        
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Ingresa tu email...',
          labelText: 'Email',
          errorText: _emailShowError ? _emailError : null,         
          suffixIcon:  const CustomSurffixIcon(svgIcon: 'assets/Mail.svg'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)
          ),
        ),
        onChanged: (value) {
          _cliente.email = value;
        },
      ),
    );
  }

  Future<void> _getClient() async {
   
    if(!_validateDocument()) {
      return;
    }
    
    setState(() {
      _showLoader=true;
    });

   
    Response response = await ApiHelper.getClienteFromHacienda(_cliente.documento);  

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

    _cliente= response.result;
   
    setState(() {
      _cliente;
     
    }); 

  }

  Future<void> _createClient() async {
    if(!_validateFields()) {
      return;
    }
     setState(() {
      _showLoader=true;
    });

    var clienteAux = _cliente.toJson();
     Response response = await ApiHelper.post("api/TransaccionesApi/PostCliente",clienteAux);    

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

     Fluttertoast.showToast(
            msg: "Cliente Creado Correctamente",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0
          );
     //make a delay to show the toast
      await Future.delayed(const Duration(seconds: 2), () {});

    setState(() {
      // widget.factura.clienteFactura = _cliente;
     //  widget.factura.clientesFacturacion.add(_cliente);
    });
   

     _goBack();
  }

 Future<void> _goBack() async {
  
  Navigator.pop(context);
  
 }
    
  bool _validateDocument() {
    bool isValid = true;
    if (_cliente.documento.isEmpty){
        _documentShowError=true;
        _documentError="Debes Ingresar un Documento";
        isValid=false;
    } else if (_cliente.documento.length < 9) {      
      _documentShowError = true;
      _documentError = 'Debes ingresar un docuemnto de al menos 9 carácteres.';
       isValid=false;
    } else {
      _documentShowError=false;
    }

    setState(() { });
    return isValid;
  } 

  bool _validateFields() {
    bool isValid = true;    

    if (_cliente.email.isEmpty) {
      isValid = false;
      _emailShowError = true;
      _emailError = 'Debes ingresar tu email.';
    } else if (!EmailValidator.validate(_cliente.email)) {
      isValid = false;
      _emailShowError = true;
      _emailError = 'Debes ingresar un email válido.';
    } else {
      _emailShowError = false;
    } 

     if (_cliente.documento.isEmpty){
        _documentShowError=true;
        _documentError="Debes Ingresar un Documento.";
        isValid=false;
    } else if (_cliente.documento.length < 9) {      
      _documentShowError = true;
      _documentError = 'Debes ingresar un docuemnto de al menos 9 carácteres.';
       isValid=false;
    } else {
      _documentShowError=false;
    }

    if(_cliente.codigoTipoID.isEmpty) {
       _documentShowError=true;
        _documentError="Por favor consulta el Documento en Hacienda.";
        isValid=false;
    } else {
      _documentShowError=false;
    }

     if(_cliente.telefono.isEmpty) {
       _telefonoShowError=true;
        _telefonoError="Por favor digite el telefono.";
        isValid=false;
    } else {
      _telefonoShowError=false;
    }

    

    
    return isValid;
  }
  
}