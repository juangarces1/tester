
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/show_client_credito.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/paid.dart';
import 'package:tester/Models/peddler.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/Models/transferencia.dart';
import 'package:tester/Models/viatico.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/Viaticos/viaticos_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';
import 'package:provider/provider.dart';




class AddViaticoScreen extends StatefulWidget {
final AllFact factura;


  // ignore: use_key_in_widget_constructors
  const AddViaticoScreen({ required this.factura});

  @override
  State<AddViaticoScreen> createState() => _AddViaticoScreenState();
}

class _AddViaticoScreenState extends State<AddViaticoScreen> {
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
  List<Viatico> viaticos = []; 

  bool placaTypeIdShowError =false;
  String placaTypeIdError ='';
  String placa = ''; 
  late Invoice invoice;
  int index = -1;

  @override
  void initState() {
    invoice =  Invoice(
    kms:0,
    observaciones: '',
    placa: '',
    detail: [],
    empleado: widget.factura.cierreActivo!.usuario,
    cierre: widget.factura.cierreActivo!.cierreFinal,
    formPago: Paid(
      totalEfectivo: 0,
      totalBac: 0, 
      totalDav: 0, 
      totalBn: 0, 
      totalSctia: 0, 
      totalDollars: 0, 
      totalCheques: 0, 
      totalCupones: 0, 
      totalPuntos: 0, 
      totalTransfer: 0, 
      clienteFactura: Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos: 0, codigo: '', telefono: ''),
      transfer: Transferencia(
        cliente: Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos: 0, codigo: '', telefono: ''),
        transfers: [], 
        monto: 0, 
        totalTransfer: 0), 
      showTotal: false,
      showFact: false, 
      totalSinpe: 0, 
      sinpe: Sinpe(
        id: 0, 
        numComprobante: '', 
        nota: '', 
        idCierre: 0, 
        nombreEmpleado: '', 
        fecha: DateTime.now(), 
        numFact: '', 
        activo: 1,
        monto: 0), 
      clientePuntos: Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos: 0, codigo: '', telefono: ''),
    ),
    isCredit: true,
    isPeddler: false,
    isProcess: false,
    isTicket: false,
    isContado: false,
    peddler: Peddler(placa: '', km: '', chofer: '',observaciones: '', orden: ''),
  
  );

   final facturasProvider = Provider.of<FacturasProvider>(context, listen: false);
          facturasProvider.facturas.add(invoice);
          index = facturasProvider.facturas.indexOf(invoice);
 
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Invoice facturaC = Provider.of<FacturasProvider>(context).getInvoiceByIndex(index);
    return SafeArea(
      child: Scaffold(
        appBar:  PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: appBar1(facturaC),
        ),
        body: Container(
          color: kContrateFondoOscuro,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                
                     SizedBox(height: SizeConfig.screenHeight * 0.04), // 4%
                      Text("Complete los Datos", style: myHeadingStyleBlack),  
                       SizedBox(height: SizeConfig.screenHeight * 0.04),  
                     ShowClientCredito(
                        index: index,                       
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        
                      ),
                        SizedBox(height: SizeConfig.screenHeight * 0.04), 
                   showPlaca(),
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                   _showMonto(),           
                    SizedBox(height: SizeConfig.screenHeight * 0.04),
                    SizedBox(
                          width: getProportionateScreenWidth(190),
                          child: DefaultButton(
                            text: "Crear",
                            press: () => _goViatico(),
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

   Widget appBar1(Invoice facturaApp) {
   return SafeArea(    
      child: Container(
        color: const Color.fromARGB(255, 219, 222, 224),
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
                    FacturaService.eliminarFactura(context, facturaApp);
                    Navigator.pop(context);
                  },           
                  child: SvgPicture.asset(
                    "assets/Back ICon.svg",
                    height: 15,
                    // ignore: deprecated_member_use
                    color: kBlueColorLogo,
                  ),
                ),
              ),
              const SizedBox(width: 10,),            
              const Text.rich(
                TextSpan(
                  text: "Nuevo Viatico",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kBlueColorLogo,
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

  List<DropdownMenuItem<String>> _getComboPlacas() {
    List<DropdownMenuItem<String>> list = [];

    list.add(const DropdownMenuItem(
      value: '',
      child: Text('Seleccione una Placa...'),
    ));

     for (var placa in invoice.formPago!.clienteCredito.placas!) {
       list.add(DropdownMenuItem(
         value: placa.toString(),
         child: Text(placa.toString()),
       ));
     }

    return list;
  }

  Widget showPlaca() {
    return Container(
          padding: const EdgeInsets.only(left: 30 , right: 30),
        child: DropdownButtonFormField(
                items: _getComboPlacas(),                
                value: placa,                
                onChanged: (option) {
                  setState(() {
                    placa = option as String; 
                                 
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Seleccione una Placa...',
                  labelText: 'Placas',
                  errorText:
                      placaTypeIdShowError ? placaTypeIdError : null,
                 
                ),
                
              ));
  }

   Widget _showMonto() {
    return Container(
         padding: const EdgeInsets.only(left: 30 , right: 30),
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

  void _goViatico() async {
    if (!_validateFields()) {
      return;
    }

    _addViatico();
  }

  bool _validateFields() {
   
    bool isValid = true;
  
    if(invoice.formPago!.clienteCredito.nombre!.isEmpty){                
                   
        Fluttertoast.showToast(
        msg: " Seleccione un cliente",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      ); 
        isValid = false;
      }

  

    if (monto.isEmpty) {
   
      montoShowError = true;
      montoError = 'Debes ingresar el monto.';
    } else {
      montoShowError = false;
    }   

   

    if (placa.isEmpty) {
      isValid = false;
      placaTypeIdShowError = true;
      placaTypeIdError = 'Debes seleccionar una Placa.';
    } else {
      bancoTypeIdShowError = false;
    }

    setState(() {});
    return isValid;
  }

  void _addViatico() async {
       
   if  (_validateFields()==false){
          return;
   }
   
   
    setState(() {
      _showLoader = true;
    });    
   

 
    

    Viatico viatico =  Viatico(idviatico: 0,
     monto: int.parse(monto),
     fecha: "2023-07-11T00:00:00",
     cedulaempleado:  widget.factura.cierreActivo!.usuario.cedulaEmpleado,     
     idcierre: widget.factura.cierreActivo!.cierreFinal.idcierre,
    //  idcliente:int.parse( widget.factura.formPago!.clientePaid.codigo),
      placa: placa,
      estado: 'PENDIENTE',  
      idcliente: int.parse( invoice.formPago!.clienteCredito.codigo!),




     );
   
   Map<String, dynamic> request = viatico.toJson();

    

    Response response = await ApiHelper.post(
      'api/Viaticos/',
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

   // widget.factura.formPago!.clientePaid= Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos:0, codigo: '',telefono: '');

    Fluttertoast.showToast(
            msg: "Viatico Creado Correctamente.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color.fromARGB(255, 20, 91, 22),
            textColor: Colors.white,
            fontSize: 16.0
          ); 
   

     // ignore: use_build_context_synchronously
      if(!mounted){
        return;
      }
       FacturaService.eliminarFactura(context, invoice);
                    Navigator.pop(context);
     Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (context) =>  ViaticosScreen(factura: widget.factura))
        );  
  }


}