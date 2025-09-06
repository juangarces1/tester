
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/peddler.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';




class PeddlersScreen extends StatefulWidget {
  final AllFact factura;
  const PeddlersScreen({ super.key, required this.factura });

  @override
  State<PeddlersScreen> createState() => _PeddlersScreenState();
}

class _PeddlersScreenState extends State<PeddlersScreen> {
  List<Peddler> peddlers = [];
  bool showLoader = false;
  late double total=0;


 
  @override

  void initState() {
    super.initState();
    _getPeddlers();
  }


 
   @override
  Widget build(BuildContext context) {
     return SafeArea(
       child: Scaffold(     
        appBar: MyCustomAppBar(
          title: 'Peddliers',
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
            
            itemCount: peddlers.length,
            itemBuilder: (context, index)  
            { 
              final item = peddlers[index].id.toString();
              return Card(
                color: kContrateFondoOscuro,
                shadowColor: kPrimaryColor,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Dismissible(  
                  resizeDuration: null,          
                  key: Key(item),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    final confirmed = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar Peddler'),
                          content: const Text('¿Estás seguro de que deseas eliminar este Peddler?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        _goDelete(peddlers[index]);
                      }
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
                    children: [    
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                'Cliente: ${peddlers[index].cliente!.nombre}',
                                style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: Colors.black, fontSize: 16),
                                maxLines: 2,
                              ),
                                               
                              Text.rich(
                                TextSpan(
                                  text: 'Producto: ${peddlers[index].products![0].detalle}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: kPrimaryColor),
                                                            
                                ),
                              ),
                                 Text.rich(
                                TextSpan(
                                  text: 'Transaccion #: ${peddlers[index].products![0].transaccion}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: kBlueColorLogo),
                                                            
                                ),
                              ),
                               Text.rich(
                                TextSpan(
                                  text: 'Cantidad: ${peddlers[index].products![0].cantidad}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: Colors.black),
                                                            
                                ),
                              ),
                               Text.rich(
                                TextSpan(
                                  text: 'Orden: ${peddlers[index].orden}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: Colors.black),
                                                            
                                ),
                              ),
                               Text.rich(
                                TextSpan(
                                  text: 'Chofer: ${peddlers[index].chofer}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: kPrimaryColor),
                                                            
                                ),
                              ),
                               Text.rich(
                                TextSpan(
                                  text: 'Observaciones: ${peddlers[index].observaciones}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: Colors.black),
                                                            
                                ),
                              ),
                               Text.rich(
                                TextSpan(
                                  text: 'Km: ${peddlers[index].km}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: Colors.black),
                                                            
                                ),
                              ),
                               Text.rich(
                                TextSpan(
                                  text: 'Placa: ${peddlers[index].placa}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: kBlueColorLogo),
                                                            
                                ),
                              ),
                               Center(
                                 child: MaterialButton( 
                                    onPressed: () => _printPeddler(peddlers[index]),                                    
                                    color: Colors.blueGrey,
                                    padding: const EdgeInsets.all(5),
                                    shape: const CircleBorder(),
                                    child:    const Icon( 
                                      Icons.print_outlined,
                                      size: 20,
                                      color: Colors.white,),
                                    ),
                               ),
                            ],
                          ),
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
       ),
     );

  }

   Future<void> _goDelete(Peddler ped) async {

     setState(() {
      showLoader = true;
    });

    
    Response response = await ApiHelper.delete('/api/Peddler/',ped.id.toString());

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

     //show floataost whit a mesage pf success
     Fluttertoast.showToast(
        msg: "Peddler eliminado con exito",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
      ); 

    setState(() {
      peddlers.remove(ped); 
      widget.factura.transacciones.add(ped.products![0]); 
                           
    }); 
    
  }

  Future<void> _getPeddlers() async {
    setState(() {
      showLoader = true;
    });

    
    Response response = await ApiHelper.getPeddlersByCierre(widget.factura.cierreActivo!.cierreFinal.idcierre ?? 0);

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
      peddlers=response.result;     
    }
    );
  }
  
  _printPeddler(Peddler peddler) {
    //  final printerProv = context.read<PrinterProvider>();
    // final device = printerProv.device;
    // if (device == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Selecciona antes un dispositivo')),
    //   );
    //   return;
    // }

    // // Llamas a tu clase de impresión
    // final testPrint = TestPrint(device: device);  
    // testPrint.printPeddler(peddler);
  }
}