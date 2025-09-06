import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/custom_surfix_icon.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';


class AddSinpeScreen extends StatefulWidget {
  final AllFact all;
  const AddSinpeScreen({super.key, required this.all});

  @override
  State<AddSinpeScreen> createState() => _AddSinpeScreenState();
}

class _AddSinpeScreenState extends State<AddSinpeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool showLoader = false;
  String comprobanteError = '';
  bool comprobanteShowError = false;
  String montoError = '';
  bool montoShowError = false;

  Sinpe sinpe = Sinpe(
    id: 0,
    activo: 0, 
    fecha: DateTime.now(),
     idCierre: 0,
      monto: 0,
       nombreEmpleado: '',       
        nota: '',
         numComprobante: '',
          numFact: '');
 
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(     
    
        appBar:  MyCustomAppBar(
           elevation: 6,
          shadowColor: kColorFondoOscuro,
          title: 'Nuevo Sinpe',
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

              signUpForm(),
              showLoader
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

  Widget signUpForm() {
     return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
             SizedBox(height: getProportionateScreenHeight(10)),
            Text("Complete los Datos", style: myHeadingStyleBlack),
            showNumComprabante(),
            SizedBox(height: getProportionateScreenHeight(10)),
            showMonto(),
            SizedBox(height: getProportionateScreenHeight(10)),
            showNota(),
            SizedBox(height: getProportionateScreenHeight(10)),
            DefaultButton(
              text: "Crear",
              press: crearSinpe,
              color: kPrimaryColor,
              gradient: kPrimaryGradientColor,
            ),
          ],
        ),
      ),
    );
  }

   Widget showNumComprabante() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: TextField(        
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Ingresa un Numero...',
          labelText: 'Comprobante',
          errorText: comprobanteShowError ? comprobanteError : null,             
          suffixIcon: const CustomSurffixIcon(svgIcon: "assets/receipt.svg"),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)
          ),
        ),
        onChanged: (value) {
          sinpe.numComprobante = value;
        },
      ),
    );
   }

    Widget showMonto() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: TextField(        
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Ingresa un Monto...',
          labelText: 'Monto',
          errorText: montoShowError ? montoError : null,             
          suffixIcon: const CustomSurffixIcon(svgIcon: "assets/receipt.svg"),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)
          ),
        ),
        onChanged: (value) {
          //parsear el valor a double        
          sinpe.monto = double.tryParse(value) ?? 0.0;
      
        },
      ),
    );
   }

    Widget showNota() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: TextField(        
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: 'Ingresa un.a nota..',
          labelText: 'Nota',
          errorText: montoShowError ? montoError : null,             
          suffixIcon: const CustomSurffixIcon(svgIcon: "assets/receipt.svg"),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)
          ),
        ),
        onChanged: (value) {
          //parsear el valor a double        
          sinpe.nota = value;
      
        },
      ),
    );
   }

   //make a function to validate the fields and show the errors
  bool validateFields() {
    bool isValid = true;
    if (sinpe.numComprobante.isEmpty) {
      isValid = false;
      comprobanteShowError = true;
      comprobanteError = 'El comprobante no puede estar vacio';
    } else {
      comprobanteShowError = false;
    }
  
    //check if the monto is a valid number
   

    if (sinpe.monto == 0) {
      isValid = false;
      montoShowError = true;
      montoError = 'El monto no puede estar vacio';
    } else {
      montoShowError = false;
    }
    return isValid;
 
 
  }

   Future<void> crearSinpe() async {
    if (!validateFields()) {
      return;
   }

    showLoader=true;
    //set the idCierre
    sinpe.idCierre = widget.all.cierreActivo!.cierreFinal.idcierre??0;
    //set the nombreEmpleado
    sinpe.nombreEmpleado = ' ${widget.all.cierreActivo!.cajero.nombre} ${widget.all.cierreActivo!.cajero.apellido1}';
    
    //set the fecha
    sinpe.fecha = DateTime.now();
    //set the activo

    Response response = await ApiHelper.post("api/Sinpes/",sinpe.toJson());

    setState(() {
      showLoader=false;
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

    //go back to the sunpes page and refresh the list
   await 
     Fluttertoast.showToast(
            msg: "Sinpe Creado Correctamente.",
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