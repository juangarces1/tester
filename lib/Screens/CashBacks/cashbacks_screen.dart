
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/cashback.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Screens/CashBacks/add_cashback_sceen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';




class CashbarksScreen extends StatefulWidget {
  final AllFact factura;

  // ignore: use_key_in_widget_constructors
  const CashbarksScreen({ required this.factura});

  @override
  State<CashbarksScreen> createState() => _CashbarksScreenState();
}

class _CashbarksScreenState extends State<CashbarksScreen> {
   List<Cashback> cashs = [];
   bool showLoader = false;
   late int total=0;
  @override

  void initState() {
    super.initState();
    _getcashsbacks();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
    
        appBar:  MyCustomAppBar(
          title: 'Cashbacks',
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
        body: showLoader ? const LoaderComponent(loadingText: 'Cargando...',) : Container(
          color: kContrateFondoOscuro,
          child: Padding(
          padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(10), vertical: getProportionateScreenHeight(10)),
          child: ListView.builder(
            
            itemCount: cashs.length,
            itemBuilder: (context, index)  
            { 
              final item = cashs[index].idcashback.toString();
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
                  _goDelete(cashs[index].idcashback ?? 0);        
                  setState(() {
                        cashs.removeAt(index);
                        total=0;                   
                        for (var element in cashs) {
                          total+=element.monto??0;
                        } 
                  });     
                  },
                  background: Container(              
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                        image: AssetImage('assets/cbs.png'),
                                    ),
                          ),
                        ),
                      ),                         
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Banco Nacional',
                              style: TextStyle(color: Colors.black, fontSize: 16),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                text: 'Monto: ${VariosHelpers.formattedToCurrencyValue(cashs[index].monto.toString())}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, color: kPrimaryColor),
                                                          
                              ),
                            )
                          ],
                        ),
                      ),
                     
                       Flexible(
                        child: MaterialButton(
                          onPressed: () => onPrintPressed(cashs[index]),
                          color: Colors.blueGrey,
                          padding: const EdgeInsets.all(5),
                          shape: const CircleBorder(),
                          child: const Icon(
                            Icons.print_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
          
          child: const Icon(Icons.add, size: 35, color: Colors.white,),
          
        ),
      
      ),
    );
  }

  Future<void> _getcashsbacks() async {
    setState(() {
      showLoader = true;
    });

    
    Response response = await ApiHelper.getCashBacks(widget.factura.cierreActivo!.cierreFinal.idcierre ?? 0);

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

    total=0;
    cashs=response.result;
    for (var element in cashs) {
      total+=element.monto??0;
    } 
    setState(() {
      cashs;
      total;
      
    });
  }

   Future<void> _goDelete(int id) async {

     setState(() {
      showLoader = true;
    });

    
    Response response = await ApiHelper.delete('/api/Cashbacks/',id.toString());

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
    
  }

  void _goAdd() async {
    String? result = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => CashbackScreen(
          factura: widget.factura,
        )
      )
    );
    if (result == 'yes') {
      _getcashsbacks();
    }
  }

   onPrintPressed(Cashback cashback) {
    // final printerProv = context.read<PrinterProvider>();
    // final device = printerProv.device;
    // if (device == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Selecciona antes un dispositivo')),
    //   );
    //   return;
    // }

    // // Llamas a tu clase de impresión
    // final testPrint = TestPrint(device: device);  
    // testPrint.printCashBack(cashback, widget.factura.cierreActivo!.cajero.nombreCompleto);

  }
}