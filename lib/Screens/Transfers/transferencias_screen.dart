
import 'package:flutter/material.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/transerencia_card.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/transparcial.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';




class TransferenciasScreen extends StatefulWidget {
   final AllFact factura;
  const TransferenciasScreen({ super.key, required this.factura });

  @override
  State<TransferenciasScreen> createState() => _TransferenciasScreenState();
}

class _TransferenciasScreenState extends State<TransferenciasScreen> {
  List<TransParcial> transfers = [];
   bool showLoader = false;
  late double total=0;

 
  @override

  void initState() {
    super.initState();
    _getTransfers();
  }


 
   @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar:  MyCustomAppBar(
          title: 'Transferencias',
          elevation: 6,
          shadowColor: kColorFondoOscuro,
          automaticallyImplyLeading: true,
          foreColor: Colors.white,
          backgroundColor: kBlueColorLogo,
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
        body:  Container(
          color: kContrateFondoOscuro,
          child: Stack(
            children: [ Padding(
            padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(10), vertical: getProportionateScreenHeight(10)),
            child: ListView.builder(
              
              itemCount: transfers.length,
              itemBuilder: (context, index)  
              { 
                
                return TransferenciaCard(transfer: transfers[index],);
                
              }        
            ),
          ),
          showLoader ? const LoaderComponent(loadingText: 'Cargando..,',) :Container()
            ]
          ),
        ),      
         bottomNavigationBar: BottomAppBar(
          color: kBlueColorLogo,
          shape: const CircularNotchedRectangle(),
          child: IconTheme(
            data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
            child: Row(
             mainAxisSize: MainAxisSize.max,
             mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                tooltip: 'Open navigation menu',
                icon: const Icon(Icons.menu),
                onPressed: () {},
              ),
                const Text('Total: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                  Text(VariosHelpers.formattedToCurrencyValue(total.toString()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
    
               ],          
             ),
          ),
         ), 
      ),
    );
  }

  Future<void> _getTransfers() async {
    setState(() {
      showLoader = true;
    });

    
    Response response = await ApiHelper.getTransfesByCierre(widget.factura.cierreActivo!.cierreFinal.idcierre ?? 0);

    setState(() {
      showLoader = false;
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
      total=0;
      transfers=response.result;
      for (var element in transfers) {
        total+=element.aplicado;
      } 
    });
  }
}