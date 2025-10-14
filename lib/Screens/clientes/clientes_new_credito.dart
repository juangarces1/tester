import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/cliente.dart';

import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:provider/provider.dart';


class ClientesNewCredito extends StatefulWidget {
  final int index; 
  

  const ClientesNewCredito({   
    super.key,
    required this.index,
   
  });

  @override
  ClientesNewCreditoState createState() => ClientesNewCreditoState();
}

class ClientesNewCreditoState extends State<ClientesNewCredito> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Cliente> _users = [];
  final List<Cliente> _filterUsers = [];
   String emailSeleccionado='';
  bool showLoader =false;
  String _searchNombre = '';
  String _searchDocument = '';
  bool _isFiltered = false; 
  late Invoice factura;
  TextStyle baseStyle = const TextStyle(
    fontStyle: FontStyle.normal, 
    fontSize: 20,
    fontWeight: FontWeight.bold, 
    color: Colors.white
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
     final clienteProvider = Provider.of<ClienteProvider>(context, listen: false);
     factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    setState(() {
     if(factura.isCredit!){
          _users=clienteProvider.clientesCredito;
     }
     else{
       _users = clienteProvider.clientesCredito.where((cliente) => cliente.tipo == "Peddler").toList();
     }
    
      
   });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Invoice facturaC = Provider.of<FacturasProvider>(context).getInvoiceByIndex(widget.index);
    return SafeArea(
   
      child: Scaffold(
        appBar:  AppBar(
          backgroundColor: kPrimaryColor,
          elevation: 6.0,
          shadowColor: Colors.white,
            title:  Text('Cliente ${facturaC.tipoInvoice}', style: baseStyle,),            
            leading: Padding(
                    padding: const EdgeInsets.all(8.0), // Adjust padding as needed
                    child: TextButton(
               style: TextButton.styleFrom(
                 shape: RoundedRectangleBorder(     
                   borderRadius: BorderRadius.circular(60),
                 ),                 
                
                 backgroundColor: Colors.white,
                 padding: EdgeInsets.zero,
               ),
               onPressed: () {
                   Navigator.of(context).pop();
               },    
               child: SvgPicture.asset(
                 "assets/Back ICon.svg",
                 height: 15,
                 // ignore: deprecated_member_use
                 color: kPrimaryColor,
               ),
             ),),         
            actions: [
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
            bottom:  TabBar(
              indicatorColor: Colors.white,
              controller: _tabController,
              labelColor: Colors.white, // Color for selected tab
              unselectedLabelColor: Colors.grey, // Color for unselected tabs
              tabs:  const [
                Tab(text: 'Buscar Por'),
                Tab(text: 'Resultados'),
              ],
            ),
          ),

        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFilterTab(),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: _getContent(facturaC),
            ),
          ],
        ),

             
      ),
    );
  } 
 
  Widget _buildFilterTab() {
  return SizedBox(
    width: double.infinity, // Ocupa todo el ancho disponible
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
           Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Codigo',
                     
                    ),
                    onChanged: (value) {
                      _searchDocument = value;
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      elevation: 5.0,
                    ),
                    onPressed: _filterByDocument, 
                    child: const Text('Buscar'),
                  ),
                ),

                
              ],
            ),
            
            
          ),
           Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      
                    ),
                    onChanged: (value) {
                      _searchNombre = value;
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      elevation: 5.0,
                    ),
                    onPressed: _filterByName, 
                    child: const Text('Buscar'),
                  ),
                ),
              ],
            ),
            
          ),
        ],
      ),
    ),
  );
}

  void _filterByName() {
      setState(() {
         _isFiltered=true;
         _filterUsers.clear();
      });

     
   for (var cliente in _users) {
        if (cliente.nombre.toLowerCase().contains(_searchNombre.toLowerCase())) {
          _filterUsers.add(cliente);
        }
      }
   if (_filterUsers.isNotEmpty) {
        setState(() {
         _filterUsers;
        
        });
       _tabController.animateTo(1);
    } 
   }

  void _filterByDocument() {
   setState(() {
    _isFiltered=true;
    _filterUsers.clear();
   });
  
   for (var cliente in _users) {
      if (cliente.codigo.contains(_searchDocument)) {
        _filterUsers.add(cliente);
      }
    }
 
   if (_filterUsers.isNotEmpty) {
        setState(() {
         _filterUsers;
        });
       _tabController.animateTo(1);
    } 
   }
   
  Widget _getContent(Invoice facturaC) {
    return _filterUsers.isEmpty 
      ? _noContent()
      : _getListView(facturaC);
  }
   
   Widget _noContent() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Text(
          _isFiltered
          ? 'No hay Usuarios con ese criterio de búsqueda.'
          : 'No hay Usuarios registradas.',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }


  Widget _getListView(Invoice facturaC) {
  return ListView.builder(
    scrollDirection: Axis.vertical,
    itemCount: _filterUsers.length,
    itemBuilder: (context, indice) {
      return Stack(
        children: [
          Column(
            children: [
              cardClienteNuevo(_filterUsers[indice], facturaC, indice),
              if (indice < _filterUsers.length - 1)
                const SizedBox(height: 8), // Espaciado entre tarjetas
            ],
          ),
            showLoader ? const LoaderComponent(loadingText: 'Procesando...'): Container(),
        ],
      );
    },
  );
}

   void _goInfoUser(Cliente clienteSel, Invoice facturaC) async {   
    clienteSel.placas;
    facturaC.formPago!.clienteCredito=clienteSel;    
    FacturaService.updateFactura(context, facturaC);
    Navigator.of(context).pop();    
  }
   
  void mostrarEditarEmailDialog(Cliente cliente, int clienteIndex) {
    String emailTemporal = cliente.email;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Correo'),
          content: TextField(
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              emailTemporal = value;
            },
            controller: TextEditingController(text: emailTemporal),
            decoration: const InputDecoration(hintText: "Introduce un nuevo correo"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                Navigator.of(context).pop(emailTemporal);
              },
            ),
          ],
        );
      },
    ).then((nuevoEmail) {
       if(!esCorreoValido(nuevoEmail)){
         Fluttertoast.showToast(
          msg: "Correo no valido",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        ); 
        return;
      }
      if (nuevoEmail != null && nuevoEmail.isNotEmpty) {
        actualizarEmailCliente(clienteIndex, nuevoEmail, cliente.email);
      }
    });
  }

  void mostrarAgregarEmailDialog(Cliente cliente, int clienteIndex) {
    String emailTemporal = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar un Correo'),
          content: TextField(
              keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              emailTemporal = value;
            },
            controller: TextEditingController(text: emailTemporal),
            decoration: const InputDecoration(hintText: "Introduce un nuevo correo"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                Navigator.of(context).pop(emailTemporal);
              },
            ),
          ],
        );
      },
    ).then((nuevoEmail) {
      if(!esCorreoValido(nuevoEmail)){
         Fluttertoast.showToast(
          msg: "Correo no valido",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        ); 
        return;
      }
      if (nuevoEmail != null && nuevoEmail.isNotEmpty) {
        agregarEmail(clienteIndex, nuevoEmail,);
      }
    });
  }

  bool esCorreoValido(String correo) {
  final regexCorreo = RegExp(
    r'^[a-zA-Z0-9._]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return regexCorreo.hasMatch(correo);
}

  void actualizarEmailCliente(int clienteIndex, String nuevoEmail, String emailAntiguo) async {
    if( nuevoEmail == emailAntiguo){
      return;
    }
     Cliente cliente = _filterUsers[clienteIndex];
      bool go = await _editEmail(nuevoEmail, emailAntiguo, cliente.codigo);
    if (go){
        setState(() {   
          cliente.email = nuevoEmail;
          // Comprueba si el nuevo correo ya está en la lista, si no, lo agrega
         
        //  cliente.emails!.firstWhere(
        //     (correo) => correo == emailAntiguo,
        //     orElse: () => "No encontrado", // Retorna esto si no se encuentra el correo
        //   );
        cliente.emails.remove(emailAntiguo);
        cliente.emails.add(nuevoEmail);
       });
    }
     
     
  }


  Widget cardClienteNuevo(Cliente e, Invoice facturaC, int index) {
  
  return Card(
    color: kContrateFondoOscuro,
    shadowColor: kPrimaryColor,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          Text(
            e.nombre, 
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
                color: kTextColorBlack,
            ),
            textAlign: TextAlign.center,
          ),                  
          
          Text(
            e.documento, 
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
                color: kColorFondoOscuro,
            ),
          ), 

           const Divider(color: Colors.grey),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                 child:  DropdownButton<String>(
                       isExpanded: true,
                    value: e.email,
                    onChanged: (String? newValue) {
                      setState(() {
                        e.email = newValue!;
                      });
                    },
                    items: e.emails.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),),
               
                  ],
                ),
              ),
            Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
              Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white, // Color de fondo blanco
                shape: BoxShape.circle, // Forma circular
              ),
              child:  IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orangeAccent,),
                    onPressed: () => mostrarEditarEmailDialog(e, index),
                ),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white, // Color de fondo blanco
                shape: BoxShape.circle, // Forma circular
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: kBlueColorLogo),
                onPressed: () {
                _getEmails(e.codigo, index);
                },
              ),
              ),
            Container(
                 width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white, // Color de fondo blanco
                shape: BoxShape.circle, // Forma circular
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: () => mostrarAgregarEmailDialog(e, index),
              ),
            ),
            
            
          ],
        ),
        const SizedBox(height: 10,),
           Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             ElevatedButton(
              style:  ButtonStyle(
                elevation: WidgetStateProperty.all(8.0),
                
              ),
              child: const Text('Select', style: TextStyle(color: kPrimaryColor),),
              onPressed: () => _goInfoUser(e, facturaC),
            ),
          ],
        ),
          // Aquí puedes incluir más widgets si es necesario
        ],
      ),
    ),
  );
}

  Future<void> _getEmails(String codigo, int index) async {
    setState(() {
      showLoader = true;
    });

    
    var response = await ApiHelper.getEmailsBy(codigo);

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

      List<String> correos = response.result;

    setState(() {
      
    

      for(String item in correos){
        if (!_filterUsers[index].emails.contains(item)) {
           _filterUsers[index].emails.add(item);
        }
      }
     
     
    });
  }

  Future<bool> _editEmail(String newEmail, String oldEmail, String codigo) async {
    setState(() {
      showLoader = true;
    });

     Map<String, dynamic> request = 
      {
        'newEmail': newEmail,
        'oldEmail' : oldEmail,
        'codCliente': codigo,
        'isCredito' : true
      };
    
    
    var response = await ApiHelper.editEmail(codigo, request);

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
       return false;
     }

      return true;
  }

  Future<bool> _addEmail(String newEmail, String codigo) async {
    setState(() {
      showLoader = true;
    });

     Map<String, dynamic> request = 
      {
        'newEmail': newEmail,
        'oldEmail' : '',
        'codCliente': codigo,
        'isCredito' : true
      };
    
    
    var response = await ApiHelper.post('api/Users', request);

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
       return false;
     }

      return true;
  }
  
  void agregarEmail(int clienteIndex, nuevoEmail) async {
   
     Cliente cliente = _filterUsers[clienteIndex];
      bool go = await _addEmail(nuevoEmail, cliente.codigo);
    if (go){
        setState(() {   
          cliente.email = nuevoEmail;    
          cliente.emails.add(nuevoEmail);
       });
    }
  }
 



}
