import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/LogIn/inventory_item.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/cart.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Screens/NewHome/new_home_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:provider/provider.dart';

class InventScreen extends StatefulWidget {

  final int cedulaEmpleado;
  final int zona;
  const InventScreen({super.key, required this.cedulaEmpleado, required this.zona});

  @override
  State<InventScreen> createState() => _InventScreenState();
}

class _InventScreenState extends State<InventScreen> {
  bool showLoader = false;
  List<InventoryItem> inventario = [];

  @override
  void initState() {
   getInventory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child:
     Scaffold(
       appBar:  MyCustomAppBar(
          title: 'Inventario Actual',
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
        body: body(),
        floatingActionButton: FloatingActionButton(
          
          backgroundColor: Colors.white,
          child:  Container(
            padding: const EdgeInsets.all(4),
            child: Image.asset('assets/Logo.png')),
          onPressed: () => mostrarDialogoConfirmacion(context,),
        ),    
      )    
    );
  }

  void mostrarDialogoConfirmacion(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmación'),
        content: const Text('¿Quieres abrir el cierre?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
            },
          ),
          TextButton(
            child: const Text('Aceptar'),
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
              crearCierre(); // Llama a tu función original
            },
          ),
        ],
      );
    },
  );
}

  Future<void> getInventory() async {
    setState(() {
      showLoader = true;
    });    
    Response response = await ApiHelper.getInventarioInicial(widget.zona);
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
        inventario = response.result;
      });
   
    } 
 
  Widget body() {
      return  Stack(
        children: [
         Container(
          color: kContrateFondoOscuro,
          child: ListView.builder(
             padding: const EdgeInsets.only(bottom: 70), 
            itemCount: inventario.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    inventario[index].article,
                    style: const TextStyle(
                      color:kBlueColorLogo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Código: ${inventario[index].code}',
                    style: const TextStyle(color: Colors.black),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.only(right: 8.0),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(width: 1.0, color: Colors.black38),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(width: 5,),
                        Text(
                          'Stock: ${inventario[index].show}',
                          style: const TextStyle(color: Colors.black, fontSize: 15 ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color.fromARGB(255, 217, 207, 10)),
                          onPressed: () {
                            // Aquí puedes cambiar el estado para mostrar un TextFormField
                            // y permitir al usuario actualizar la cantidad
                            _showEditDialog(context, inventario[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

          showLoader ? const LoaderComponent(loadingText: 'Cargando...',) : Container(),
        ],
      );
  }

  void _ajustarInventario (InventoryItem item, int ajuste ) {
    setState(() {
      item.show=ajuste;
      item.adjustment=ajuste;
    });

  }

    void _showEditDialog(BuildContext context, InventoryItem item) {
      String? ajuste = item.quantity.toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Cantidad'),
          content: TextFormField(
            initialValue: item.show.toString(),
            keyboardType: TextInputType.number,
            onChanged: (newValue) {
             ajuste = newValue;
            },
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {      
               // Aquí se guardaría el nuevo valor de la cantidad
                int pass = int.parse(ajuste??'0');              
                 _ajustarInventario(item, pass);  
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> crearCierre() async {
    setState(() {
      showLoader = true;
    });    

     Map<String, dynamic> request = 
      {
        'inventario': inventario.map((e) => e.toJson()).toList(),
        'idzona' : widget.zona,
        'cedUsuario' : widget.cedulaEmpleado,     
      };

    Response response = await ApiHelper.post("Api/Users/CrearCierre", request);  
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

      var decodedJson = jsonDecode(response.result);

      AllFact factura = AllFact.fromJson(decodedJson);

   

    factura.cart = Cart(products: [], numOfItem: 0);
    if(!mounted){
      return;
    }

     final clienteProvider = Provider.of<ClienteProvider>(context, listen: false);
      clienteProvider.setClientesContado(factura.clientesFacturacion);
      //  clienteProvider.setClientesCredito(factura.clientesCredito);


    factura.placa='';
    factura.kms=0;
    factura.lasTr=0;
    
   
    //ordenamos las transacciones de mayor a menor y adjudicamos la ultima transaccion
    if(factura.transacciones.isNotEmpty){
     factura.transacciones.sort(((b, a) => a.transaccion.compareTo(b.transaccion)));
     factura.lasTr=factura.transacciones.first.transaccion;
    }    
    
    goHome(factura);

   
  } 

    void goHome (AllFact factura) {  
     Navigator.pushReplacement(
       context, 
       MaterialPageRoute(
         builder: (context) => const NewHomeScreen()
       )
     );
  }
  
 
}