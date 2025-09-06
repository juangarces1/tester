
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/cierredatafono.dart';
import 'package:tester/Models/datafono.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';

class DatafonoScreen extends StatefulWidget {
final AllFact factura;

  // ignore: use_key_in_widget_constructors
  const DatafonoScreen({ required this.factura});

  @override
  State<DatafonoScreen> createState() => _DatafonoScreenState();
}

class _DatafonoScreenState extends State<DatafonoScreen> {
  bool _showLoader = false;
  String monto = '';  
  String lote = '';  
  String montoError = '';
  bool montoShowError = false;
  String loteError = '';
  bool loteShowError = false;
  TextEditingController montoController = TextEditingController();
  TextEditingController loteController = TextEditingController();
  String datafonoNombre = '';
  String bancoTypeIdError = '';
  bool bancoTypeIdShowError = false;
  List<Datafono> datafonos = []; 

   @override
  void initState() {
    super.initState();
    _getDatafonos();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar:  MyCustomAppBar(
           elevation: 6,
          shadowColor: kColorFondoOscuro,
          title: 'Nuevo Cierre Datafono',
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
        body: Container(
          color: kContrateFondoOscuro,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    SizedBox(height: SizeConfig.screenHeight * 0.04), // 4%
                    Text("Llene el formulario", style: myHeadingStyleBlack),  
                     SizedBox(height: SizeConfig.screenHeight * 0.04), 
                   _showDatafonos(),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                   _showMonto(),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                     _showLote(),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                    SizedBox(
                          width: getProportionateScreenWidth(190),
                          child: DefaultButton(
                            text: "Crear",
                            press: () => _goDatafono(),
                            color: kPrimaryColor,
                            gradient: kPrimaryGradientColor,
                          ),
                        ),
                  ],
                ),
              ),
              _showLoader
                  ? const LoaderComponent(
                      loadingText: 'Por favor espere...',
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getDatafonos() async {
    setState(() {
      _showLoader = true;
    });

    Response response = await ApiHelper.getDatafonos();

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

    setState(() {
      datafonos = response.result;
    });
  }

  List<DropdownMenuItem<String>> _getComboDatafonos() {
    List<DropdownMenuItem<String>> list = [];

    list.add(const DropdownMenuItem(
      value: '',
      child: Text('Seleccione un Datafono...'),
    ));

    for (var datafono in datafonos) {
      list.add(DropdownMenuItem(
        value: datafono.nombre,
        child: Text(datafono.nombre.toString()),
      ));
    }

    return list;
  }

  Widget _showDatafonos() {
    return Container(
         padding: const EdgeInsets.only(left: 50.0, right: 50), 
        child: datafonos.isEmpty
        
            ? const Text('Cargando...')
            : DropdownButtonFormField(
                items: _getComboDatafonos(),                
                value: datafonoNombre,                
                onChanged: (option) {
                  setState(() {
                    datafonoNombre = option as String;                   
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Seleccione un Datafono...',
                  labelText: 'Datafonos',
                  errorText:
                      bancoTypeIdShowError ? bancoTypeIdError : null,
                 
                ),
                
              ));
  }

   Widget _showMonto() {
    return Container(
      padding: const EdgeInsets.only(left: 50.0, right: 50),      
      child: TextField(
        controller: montoController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Ingresa el Monto...',
          labelText: 'Monto',
          errorText: montoShowError ? montoError : null,
          suffixIcon: const Icon(Icons.attach_money_rounded),
         
        ),
        onChanged: (value) {
          monto =  value;
        },
      ),
    );
  }

   Widget _showLote() {
    return Container(
      padding: const EdgeInsets.only(left: 50.0, right: 50),      
      child: TextField(
        controller: loteController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Ingresa el lote...',
          labelText: 'Lote',
          errorText: loteShowError ? loteError : null,
          suffixIcon: const Icon(Icons.numbers_outlined),
         
        ),
        onChanged: (value) {
          lote =  value;
        },
      ),
    );
  }

  void _goDatafono() async {
    if (!_validateFields()) {
      return;
    }

    _addDatafono();
  }

  bool _validateFields() {
    bool isValid = true;

    if (monto.isEmpty) {
      isValid = false;
      montoShowError = true;
      montoError = 'Debes ingresar el monto.';
    } else {
      montoShowError = false;
    }   

     if (loteController.text.isEmpty) {
      isValid = false;
      loteShowError = true;
      loteError = 'Debes ingresa el lote.';
    } else {
      loteShowError = false;
    }   

    if (datafonoNombre.isEmpty) {
      isValid = false;
      bancoTypeIdShowError = true;
      bancoTypeIdError = 'Debes seleccionar un Datafono.';
    } else {
      bancoTypeIdShowError = false;
    }

    setState(() {});
    return isValid;
  }

  void _addDatafono() async {
    setState(() {
      _showLoader = true;
    });    
   

   final data =
      datafonos.firstWhere((element) =>
          element.nombre == datafonoNombre);
          
   
    CierreDatafono datafono =  CierreDatafono(idcierredatafono:  int.parse(loteController.text),
     monto: double.parse(monto),
     fechacierre: "2023-07-11T00:00:00",
     cedulaempleado:  widget.factura.cierreActivo!.usuario.cedulaEmpleado,
     idbanco: data.idbanco, 
     idcierre: widget.factura.cierreActivo!.cierreFinal.idcierre,
     terminal: data.nombre,
     idregistrodatafono: 0,   
     banco: data.nombre, 

     );
   
   Map<String, dynamic> request = datafono.toJson();

    

    Response response = await ApiHelper.post(
      'api/CierreDatafonos/',
      request,
    );

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
            msg: "Cierre Datafono Creado Correctamente.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor:const Color.fromARGB(255, 20, 91, 22),
            textColor: Colors.white,
            fontSize: 16.0
          ); 

    

    // ignore: use_build_context_synchronously
    Navigator.pop(context, 'yes');
  }


}