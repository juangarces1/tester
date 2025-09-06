
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/bank.dart';
import 'package:tester/Models/cheque.dart';
import 'package:tester/Models/deposito.dart';
import 'package:tester/Models/dollar.dart';
import 'package:tester/Models/money.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';



class EntregaEfectivoScreen extends StatefulWidget {
  final AllFact factura;
  const EntregaEfectivoScreen({ super.key, required this.factura });

  @override
  State<EntregaEfectivoScreen> createState() => _EntregaEfectivoScreenState();
}

class _EntregaEfectivoScreenState extends State<EntregaEfectivoScreen> {
  bool _showLoader = false;
  String monto = '';
  String montoError = '';
  bool montoShowError = false;
  bool showDollar = false;
  bool showCheque=false;

  String cantDollarError ='';
  bool cantDollarShowError =false;

  String precioDollaError ='';
  bool precioDollarShowError =false;

  bool bankShowError =false;
  String bankError='';


 bool idChequeShowError =false;
  String idChequeError='';
  


 TextEditingController idChequeController = TextEditingController();

  TextEditingController montoController = TextEditingController();
  TextEditingController cantDollarController = TextEditingController();
  TextEditingController cambioDollarController = TextEditingController();
  
  String moneda = '';
  int idmoneda=0;
  String moneyTypeIdError = '';
  bool moneyTypeIdShowError = false;
  List<Money> moneys = [];
  List<Bank> banks = [];
  int idbank=0;

 

   @override
  void initState() {
    super.initState();
    _getMoneys();
    _getBanks();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar:  MyCustomAppBar(
           elevation: 6,
          shadowColor: kColorFondoOscuro,
          title: 'Nuevo Deposito',
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
                   _showMoneys(),
                     
                    showCheque ? SizedBox(height: SizeConfig.screenHeight * 0.04) : Container(),
                    showCheque ? _showBanks() : Container(),
                    showCheque ? SizedBox(height: SizeConfig.screenHeight * 0.04) : Container(),
                     showCheque ? _showIdCheque() : Container(),
                    
                    showDollar ? SizedBox(height: SizeConfig.screenHeight * 0.04) : Container(),
                    showDollar ? _showCantidadDollar() : Container(),
                    showDollar ? SizedBox(height: SizeConfig.screenHeight * 0.04) : Container(),
                     showDollar ? _showPrecioCambioDollar() : Container(),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                   _showMonto(),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                    SizedBox(
                          width: getProportionateScreenWidth(190),
                          child: DefaultButton(
                            text: "Crear",
                            press: () => _goDeposito(),
                            color: kPrimaryColor,
                            gradient: kPrimaryGradientColor,
                          ),
                        ),
                  ],
                ),
              ),
              _showLoader
                  ? const LoaderComponent(
                      loadingText: 'Procesando...',
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getMoneys() async {
    setState(() {
      _showLoader = true;
    });   

    Response response = await ApiHelper.getMoneys();

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
      moneys = response.result;
    });
  }

  List<DropdownMenuItem<String>> _getComboMoney() {
    List<DropdownMenuItem<String>> list = [];

    list.add(const DropdownMenuItem(
      value: '',
      child: Text('Seleccione una Moneda...'),
    ));

    for (var money in moneys) {
      list.add(DropdownMenuItem(
        value: money.nombre,
        child: Text(money.nombre.toString()),
      ));
    }

    return list;
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

  Widget _showMoneys() {
    return Container(
         padding: const EdgeInsets.only(left: 50.0, right: 50), 
        child: moneys.isEmpty
            ? const Text('Cargando...')
            : DropdownButtonFormField(
                items: _getComboMoney(),
                value: moneda,
                onChanged: (String? newValue) {
                  setState(() {
                    moneda = newValue.toString();                   
                    moneda=='DÓLAR' ? showDollar = true : showDollar =false;
                    moneda=='CHEQUE' ? showCheque = true : showCheque =false;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Seleccione una moneda...',
                  labelText: 'Deposito',
                  errorText:
                      moneyTypeIdShowError ? moneyTypeIdError : null,
                 
                ),
              ));
  }

   Widget _showBanks() {
    return Container(
         padding: const EdgeInsets.only(left: 50.0, right: 50), 
        child: moneys.isEmpty
            ? const Text('Cargando...')
            : DropdownButtonFormField(
                items: _getComboBanks(),
                value: idbank,
                onChanged: (value) {
                  setState(() {
                    idbank =  value as int;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Seleccione un Banco...',
                  labelText: 'Bancos',
                  errorText:
                      bankShowError ? bankError : null,
                 
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

   Widget _showIdCheque() {
    return Container(
      padding: const EdgeInsets.only(left: 50.0, right: 50),      
      child: TextField(
        controller: idChequeController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Ingress el Numero del Cheque',
          labelText: 'Cheque #',
          errorText: idChequeShowError ? idChequeError : null,
          suffixIcon: const Icon(Icons.numbers_outlined),
         
        ),
        onChanged: (value) {
          monto =  value;
        },
      ),
    );
  }

   Widget _showCantidadDollar() {
    return Container(
      padding: const EdgeInsets.only(left: 50.0, right: 50),      
      child: TextField(
        controller: cantDollarController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Ingrese la cantidad en dolares',
          labelText: 'Dollares',
          errorText: cantDollarShowError ? cantDollarError : null,
          suffixIcon: const Icon(Icons.attach_money_rounded),
         
        ),
        onChanged: (value) {
          monto =  value;
        },
      ),
    );
  }

  Widget _showPrecioCambioDollar() {
    return Container(
      padding: const EdgeInsets.only(left: 50.0, right: 50),      
      child: TextField(
        controller: cambioDollarController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Ingrese el valor por cada Dollar',
          labelText: 'Cambio',
          errorText: precioDollarShowError ? precioDollaError : null,
          suffixIcon: const Icon(Icons.attach_money_rounded),
         
        ),
        onChanged: (value) {
          monto =  value;
        },
      ),
    );
  }

  void _goDeposito() async {
    if (!_validateFields()) {
      return;
    }

    _addMoney();
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

    if (moneda.isEmpty) {
      isValid = false;
      moneyTypeIdShowError = true;
      moneyTypeIdError = 'Debes seleccionar una moneda.';
    } else {
      moneyTypeIdShowError = false;
    }

    if(showDollar){
      if (cantDollarController.text.isEmpty) {
      isValid = false;
      cantDollarShowError = true;
      cantDollarError = 'Debes ingresar una cantidad en dolares.';
      } 
      else {
        cantDollarShowError = false;
      }

      if (cambioDollarController.text.isEmpty) {
      isValid = false;
      precioDollarShowError = true;
      precioDollaError = 'Debes ingresar un precio por dolar.';
      } 
      else {
        precioDollarShowError = false;
      }
    }

     if(showCheque){
      if (idbank==0) {
      isValid = false;
      bankShowError = true;
      bankError = 'Debes Seleccionar un Banco.';
      } 
      else {
        bankShowError = false;
      }

      if (idChequeController.text.isEmpty) {
      isValid = false;
      idChequeShowError = true;
      idChequeError = 'Debes ingresar un numero de cheque.';
      } 
      else {
        idChequeShowError = false;
      }
    }

    setState(() {});
    return isValid;
  }

  void _addMoney() async {
    setState(() {
      _showLoader = true;
    });    

    Deposito deposito = Deposito(idcierre: widget.factura.cierreActivo!.cierreFinal.idcierre,
    iddeposito: 0,
    cedulaempleado: widget.factura.cierreActivo!.usuario.cedulaEmpleado,
    moneda: moneda,
    monto: int.parse(monto),
    fechadepostio: "2023-07-11T00:00:00",
    );   
   
   Map<String, dynamic> request = deposito.toJson();   

    Response response = await ApiHelper.post(
      'api/Depositos/',
      request,
    );

    Response responseDollar = Response(isSuccess: true);
    if(showDollar){  

        Dollar dollar = Dollar(
          id: 0,
          cantidad: int.parse(cantDollarController.text),
          preciocambio: int.parse(cambioDollarController.text),
          monto:  int.parse(monto),
          idcierre: widget.factura.cierreActivo!.cierreFinal.idcierre,
        );

        Map<String, dynamic> request1 = dollar.toJson();       

         responseDollar = await ApiHelper.post(
          'api/Cierres/PostDollar',
          request1,
        );
    }

    Response responseCheque = Response(isSuccess: true);
    if(showCheque){  

        Cheque cheque = Cheque(
          idcheque: int.parse(idChequeController.text),
          idbanco: idbank,
          cedulaempleado: widget.factura.cierreActivo!.usuario.cedulaEmpleado,
          monto:  int.parse(monto),
          idcierre: widget.factura.cierreActivo!.cierreFinal.idcierre,
        );

        Map<String, dynamic> request2 = cheque.toJson();       

         responseCheque = await ApiHelper.post(
          'api/Cierres/PostCheque',
          request2,
        );

    }

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

     if (!responseDollar.isSuccess) {
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

     if (!responseCheque.isSuccess) {
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
          msg: "Deposito Creado Correctamente.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: const Color.fromARGB(255, 42, 101, 44),
          textColor: Colors.white,
          fontSize: 16.0
        );

    

    // ignore: use_build_context_synchronously
    Navigator.pop(context, 'yes');
  }
}