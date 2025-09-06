
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/bank.dart';
import 'package:tester/Models/cashback.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';



class CashbackScreen extends StatefulWidget {
final AllFact factura;

  // ignore: use_key_in_widget_constructors
  const CashbackScreen({ required this.factura});

  @override
  State<CashbackScreen> createState() => _CashbackScreenState();
}

class _CashbackScreenState extends State<CashbackScreen> {
  bool _showLoader = false;
  String monto = '';
  String montoError = '';
  bool montoShowError = false;
  TextEditingController montoController = TextEditingController();
  int idbanco = 0;
  String bancoTypeIdError = '';
  bool bancoTypeIdShowError = false;
  List<Bank> banks = []; 

   @override
  void initState() {
    super.initState();
    _getBanks();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(     
    
        appBar:  MyCustomAppBar(
           elevation: 6,
          shadowColor: kColorFondoOscuro,
          title: 'Nuevo Cashback',
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
                   _showBanks(),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                   _showMonto(),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                    SizedBox(
                          width: getProportionateScreenWidth(190),
                          child: DefaultButton(
                            text: "Crear",
                            press: () => _goCashback(),
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

  Future<void> _getBanks() async {
    setState(() {
      _showLoader = true;
    });

   

    Response response = await ApiHelper.getBanks();

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
      banks = response.result;
    });
  }

  List<DropdownMenuItem<int>> _getComboBanks() {
    List<DropdownMenuItem<int>> list = [];

    list.add(const DropdownMenuItem(
      value: 0,
      child: Text('Seleccione un Banco...'),
    ));

    for (var bank in banks) {
      list.add(DropdownMenuItem(
        value: bank.idbanco,
        child: Text(bank.nombre.toString()),
      ));
    }

    return list;
  }

  Widget _showBanks() {
    return Container(
         padding: const EdgeInsets.only(left: 50.0, right: 50), 
        child: banks.isEmpty
            ? const Text('Cargando...')
            : DropdownButtonFormField(
                items: _getComboBanks(),
                value: idbanco,
                onChanged: (option) {
                  setState(() {
                    idbanco = option as int;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Seleccione un Banco...',
                  labelText: 'Bancos',
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

  void _goCashback() async {
    if (!_validateFields()) {
      return;
    }

    _addCashback();
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

    if (idbanco == 0) {
      isValid = false;
      bancoTypeIdShowError = true;
      bancoTypeIdError = 'Debes seleccionar un banco.';
    } else {
      bancoTypeIdShowError = false;
    }

    setState(() {});
    return isValid;
  }

  void _addCashback() async {
    setState(() {
      _showLoader = true;
    });    

    

    Cashback cashback =  Cashback(idcashback: 0,
     monto: int.parse(monto),
     fechacashback: "2023-07-11T00:00:00",
     cedulaempleado:  widget.factura.cierreActivo!.usuario.cedulaEmpleado,
     idbanco: idbanco, 
     idcierre: widget.factura.cierreActivo!.cierreFinal.idcierre);
   
   Map<String, dynamic> request1 = cashback.toJson();

    

    Response response = await ApiHelper.post(
      'api/Cashbacks/',
      request1,
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

    await 
     Fluttertoast.showToast(
            msg: "Cashback Creado Correctamente.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color.fromARGB(255, 20, 91, 22),
            textColor: Colors.white,
            fontSize: 16.0
          ); 
    

    // ignore: use_build_context_synchronously
    Navigator.pop(context, 'yes');
  }


}