import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:intl/intl.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/Screens/Sinpes/add_sinpe_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

class SinpesScreen extends StatefulWidget {
 final AllFact all;
  const SinpesScreen({super.key, required this.all});

  @override
  State<SinpesScreen> createState() => _SinpesScreenState();
}

class _SinpesScreenState extends State<SinpesScreen> {
   List<Sinpe> sinpes = [];
   bool showLoader = false;
   late double total=0;
  @override

  void initState() {
    super.initState();
    _getSinpes();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
    
        appBar: MyCustomAppBar(
          title: 'Sinpes',
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
        body: showLoader ? const LoaderComponent(loadingText: 'Cargando...',) : 
        Container(
          color: kContrateFondoOscuro,
          child: Padding(
          padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(10), vertical: getProportionateScreenHeight(10)),
          child: ListView.builder(
            
            itemCount: sinpes.length,
            itemBuilder: (context, index)  
            { 
              final item = sinpes[index].id.toString();
              return Card(
                color: kContrateFondoOscuro,
                shadowColor: kPrimaryColor,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Dismissible(            
                  key: Key(item),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {              
                  _goDelete(sinpes[index], index);        
                 
                  },
                  background: Container(              
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6E6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                     child: Row(
                      children: [
                        const Spacer(),
                        SvgPicture.asset("assets/Trash.svg"),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 88,
                        child: AspectRatio(
                          aspectRatio: 0.88,
                          child: Container(
                            padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child:  const Image(
                                        image: AssetImage('assets/sinpe.png'),
                                        fit: BoxFit.fill,
                                    ),
                          ),
                        ),
                      ),                         
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              sinpes[index].activo == 1 ? 'Estado: Aplicado' : 'Estado: Disponible',
                              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines:1,
                            ),
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(sinpes[index].fecha)}',
                              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines:1,
                            ),
                            Text(
                              'Pistero: ${sinpes[index].nombreEmpleado}',
                              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines:1,
                            ),
                         
                            Text.rich(
                              TextSpan(
                                  text: 'Monto: ${VariosHelpers.formattedToCurrencyValue(sinpes[index].monto.toString())}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, color: kPrimaryColor),
                                                          
                              ),
                            ),
                               Text(
                              'Nota: ${sinpes[index].nota}',
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  
                ),
             ),
              );
            }        
          ),
          ),
        ),
    
         bottomNavigationBar: BottomAppBar(
          color: kBlueColorLogo,
          
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
       
        floatingActionButton: FloatingActionButton(
          
          backgroundColor: kPrimaryColor,
          onPressed: () => _goAdd(),
          
          child: const Icon(Icons.add, color: Colors.white,size: 30,),
          
        ),
      
      ),
    );
  }

  Future<void> _getSinpes() async {
    setState(() {
      showLoader = true;
    });

    
    Response response = await ApiHelper.getSinpes(widget.all.cierreActivo!.cierreFinal.idcierre ?? 0);

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
        sinpes=response.result;
        for (var element in sinpes) {
          total+=element.monto;
        } 
      
    });
  }

   Future<void> _goDelete(Sinpe sinpe, int index) async {
      
      if(sinpe.activo==1){
       Fluttertoast.showToast(
        msg: "No se puede eliminar un sinpe aplicado",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      ); 
        return;
      }

     setState(() {
      showLoader = true;
    });

    
    Response response = await ApiHelper.delete('/api/Sinpes/', sinpe.id.toString());

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
          sinpes.removeAt(index);
          total=0;                   
          //calculate the total of the field monto
          for (var element in sinpes) {
            total+=element.monto;
          } 
        
    });     
    
  }

  void _goAdd() async {
    String? result = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => AddSinpeScreen(
          all: widget.all,
        )
      )
    );
    if (result == 'yes') {
      _getSinpes();
    }
  }
}