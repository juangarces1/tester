import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/no_contetnt.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/paid.dart';
import 'package:tester/Models/peddler.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/Models/transferencia.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/CashBacks/cashbacks_screen.dart';
import 'package:tester/Screens/CierreDatafonos/cierre_datafonos_screen.dart';
import 'package:tester/Screens/Depositos/depositos_screen.dart';
import 'package:tester/Screens/Facturas/facturas_screen.dart';
import 'package:tester/Screens/NewHome/Components/first_page.dart';
import 'package:tester/Screens/NewHome/Components/show_process.dart';
import 'package:tester/Screens/Peddlers/peddlers_add_screen.dart';
import 'package:tester/Screens/Peddlers/peddlers_screen.dart';
import 'package:tester/Screens/ResumenCierre/resumen_cierre.dart';
import 'package:tester/Screens/Sinpes/sinpes_screen.dart';
import 'package:tester/Screens/Transacciones/transacciones_screen.dart';
import 'package:tester/Screens/Transfers/transferencias_screen.dart';
import 'package:tester/Screens/Viaticos/viaticos_screen.dart';
import 'package:tester/Screens/checkout/checkount.dart';
import 'package:tester/Screens/credito/credit_process_screen.dart';
import 'package:tester/Screens/logIn/login_screen.dart';
import 'package:tester/Screens/test_print/print_screen.dart';
import 'package:tester/Screens/tickets/ticket_screen.dart';
import 'package:tester/ViewModels/beache_models.dart';
import 'package:tester/ViewModels/new_map.dart';
import 'package:tester/helpers/console_api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

import '../../constans.dart';
import '../../sizeconfig.dart';


class NewHomeScreen extends StatefulWidget {  
  const NewHomeScreen({ 
    super.key, 
    required this.factura,
     
  });

  final AllFact factura; 
  
  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen>  {
 
  double aspectRetio = 1.02;
  int _selectedIndex = 0;
  

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  TextStyle baseStyle = const TextStyle(
      fontStyle: FontStyle.normal, 
      fontSize: 18,
      fontWeight: FontWeight.bold, 
      color: Colors.white
    );


    
 @override
 Widget build(BuildContext context) {
    final pages = <Widget>[
    const FirstPage(),
    DispensersDashboard(
       key: const PageStorageKey('dispensers'),
      isActive: _selectedIndex == 1,
    ),
     _buildFacturacionPage(),         
     
  ];
     return SafeArea( 
       child: Scaffold(
        appBar: _buildCustomAppBar(),
        key: _scaffoldKey,
        backgroundColor: kColorFondoOscuro,         
        body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 1, 18, 59),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.2),  ),
            ],
          ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                  child: GNav(
                    rippleColor: Colors.grey[300]!,
                    hoverColor: Colors.grey[100]!,
                    gap: 8,
                    activeColor: Colors.white,
                    iconSize: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    duration: const Duration(milliseconds: 400),
                    tabBackgroundColor: Colors.grey[900]!,
                    color: Colors.white,
                    tabs: const [
                      GButton(
                        icon: Icons.ev_station,
                        text: 'Inicio',
                      ),
                      GButton(
                        icon: Icons.ev_station,
                        text: 'Estado',
                      ),
                       GButton(
                        icon: Icons.receipt_long,
                        text: 'Facturación',
                      ),
                     
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                ),
              ),
            ),
          drawer: _getAdminMenu(),
       ),
     );
}

PreferredSizeWidget _buildCustomAppBar() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(70.0), // Ajusta la altura según tus necesidades
    child: AppBar(
      automaticallyImplyLeading: true,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        padding: const EdgeInsets.only(left: 20, top: 5, right: 0, bottom: 0),
        decoration: const BoxDecoration(
          gradient: kGradientHome,
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor,
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              const Text('Fuel Red Mobile', style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                             Text('Usuario: ${widget.factura.cierreActivo!.usuario.nombre} ${widget.factura.cierreActivo!.usuario.apellido1}',
                             style: baseStyle),
                                                    
                          ],       
                        ),
                       
                      
                      ],
                    ),
        ),
      ),
    
    ),
  );
}

Widget gridFacturacion() {
  return Consumer<FacturasProvider>(
    builder: (context, facturasProvider, child) {
      return facturasProvider.facturas.isNotEmpty  ? Container(
         color: const Color.fromARGB(255, 39, 40, 41),
        child: Padding(
           padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Dos columnas
              crossAxisSpacing: 10, // Espacio horizontal entre tarjetas
              mainAxisSpacing: 10, // Espacio vertical entre tarjetas
            ),
            itemCount: facturasProvider.facturas.length,
            itemBuilder: (context, index) {
              return _crearTarjetaFactura(facturasProvider.facturas[index]);
            },
          ),
        ),
      ) : Container(
          color: const Color.fromARGB(255, 34, 35, 36),
          child: const MyNoContent(
            text: 'No hay Facturas...', 
            backgroundColor: Colors.black45,
            borderColor: Colors.black,
            borderWidth: 0.5,
          )
        );
    },
  );
}

Widget _crearTarjetaFactura(Invoice factura) {
  return Stack(
    children: [
      Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(10)),
        decoration: BoxDecoration(
          color: VariosHelpers.getShadedColor(factura.total.toString() , kColorFondoOscuro),
          borderRadius: BorderRadius.circular(15),
        ),
       
        width: getProportionateScreenWidth(170),   
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [   
            const SizedBox(height: 8,), 
             Text(
             factura.tipoInvoice,
              style: TextStyle(
                fontSize: getProportionateScreenWidth(20),
                fontWeight: FontWeight.bold,
                color: 
                factura.isPromo! ? Colors.black 
                : factura.isContado! ? Colors.orange 
                : factura.isTicket! ? Colors.green 
                : factura.isCredit! ? Colors.blue 
                :  Colors.yellow               
                
              ),
            ),      
                 const SizedBox(height: 11,),         
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Material(                
                color: VariosHelpers.getShadedColor(factura.total.toString() , kColorFondoOscuro),
                  child: Ink.image(                        
                    image: 
                         AssetImage(factura.isContado! ? 'assets/factura.png'
                          : factura.isTicket! ? 'assets/Ticket.png' 
                          : factura.isCredit! ?  'assets/Cred1.png' 
                          : factura.isPeddler! ? 'assets/peddler.png' : 'assets/factura.png',),
                      fit: BoxFit.cover,
                      child: InkWell(
                           onTap: () => navegarSegunTipoInvoice(context,  factura),
                      ),
                    ),
                  ),
                ),
              ),
            
                 
        factura.isTicket! ? Container() 
        : Text(
            factura.isCredit! ? factura.formPago!.clienteCredito.obtenerPrimerNombre() 
            : factura.isPeddler! ? factura.formPago!.clienteCredito.obtenerPrimerNombre() 
            : factura.isContado! ? factura.formPago!.clienteFactura.obtenerPrimerNombre() 
            : 'hey',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(16),
              fontWeight: FontWeight.normal,
              color: kColorMenu,
            ),
          ),
          Text(
            VariosHelpers.formattedToCurrencyValue(factura.total.toString()),
            style:  TextStyle(
              fontSize: getProportionateScreenWidth(18),
              fontWeight: FontWeight.bold,
              color: Colors.white,

            ),
          )
        ]),
        ),
     Positioned(
        top: 0, // Ajusta según necesidad
        right: 0, // Ajusta según necesidad
        child: Container(
          //width: getProportionateScreenWidth(20),
          decoration: BoxDecoration(
            
            color: Colors.white.withOpacity(0.3), // Fondo blanco para el botón
            shape: BoxShape.circle, // Forma circular
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1), // Cambios en la sombra
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red), // Icono de basurero en color rojo
                onPressed: () => _eliminarFactura(context, factura),
                tooltip: 'Eliminar Factura',
              ),
    ),
  ),
  
   
    ],
  );
}

void navegarSegunTipoInvoice(BuildContext context, Invoice invoice) {
   var facturasProvider = Provider.of<FacturasProvider>(context, listen: false);
   int index = facturasProvider.facturas.indexOf(invoice);  

  if (invoice.isCredit == true) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProceeeCreditScreen(index: index,)));
   }  else if (invoice.isPeddler == true) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PeddlersAddScreen(index: index,)));
  }  else if (invoice.isContado == true) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CheaOutScreen(index: index,)));
  } else if (invoice.isTicket == true) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => TicketScreen(index: index,)));
  } else if (invoice.isProcess == true) {
   //  Navigator.push(context, MaterialPageRoute(builder: (context) => ProcessPage()));
  } else {
    // Manejar el caso en que ninguno de los booleanos es verdadero
    // Por ejemplo, mostrar un mensaje o navegar a una página por defecto
   // Navigator.push(context, MaterialPageRoute(builder: (context) => DefaultPage()));
  }
}

void _eliminarFactura(BuildContext context, Invoice factura) {
  // Muestra un diálogo de confirmación
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Eliminar'),
        content:  Text('¿Estás seguro de que quieres eliminar ${factura.tipoInvoice}?'),
        actions: <Widget>[
       TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue, textStyle: const TextStyle(fontWeight: FontWeight.bold), // Texto en negrita
          ),
          child: const Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop(); // Cierra el diálogo
          },
        ),

         ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.red, // Color del texto blanco
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Borde redondeado
              ),
            ),
            child: const Text('Eliminar'),
            onPressed: () {
              // Lógica para eliminar la factura
              FacturaService.eliminarFactura(context, factura);
              Navigator.of(context).pop(); // Cierra el diálogo
            },
          ),
        ],
      );
    },
  );
}

void _mostrarMenu(BuildContext context) {
  // Crear una nueva factura
  Invoice nuevaFactura = Invoice(
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
    isCredit: false,
    isPeddler: false,
    isProcess: false,
    isTicket: false,
    isContado: false,
    isPromo : false,
    peddler: Peddler(placa: '', km: '', chofer: '',observaciones: '', orden: ''),
  

  
    

  ); // Asegúrate de reemplazar esto con la lógica correcta para crear una nueva factura

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Center(child: Text('Elige una opción', style:  TextStyle(fontWeight: FontWeight.bold),)),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              _crearBotonOpcion(context, 'Contado', nuevaFactura, kPrimaryColor),
              _crearBotonOpcion(context, 'Ticket', nuevaFactura, Colors.green),
              _crearBotonOpcion(context, 'Credito', nuevaFactura, kBlueColorLogo),
              _crearBotonOpcion(context, 'Peddler', nuevaFactura, const Color.fromARGB(255, 196, 177, 5)),
             
              // Agrega los otros botones aquí, pasando la misma nuevaFactura
            ],
          ),
        ),
      );
    },
  );
}

Widget _crearBotonOpcion(BuildContext context, String texto, Invoice invoice, Color color) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, 
        backgroundColor: color,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      //  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.of(context).pop();
    
         final facturasProvider = Provider.of<FacturasProvider>(context, listen: false);
            
         int index = facturasProvider.addInvoice(invoice);
    
        // Navegar al widget correspondiente con la nueva factura
        if (texto == 'Contado') {
          invoice.isContado=true;
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => CheaOutScreen(index: index)));
        } else if (texto == 'Ticket') {
          invoice.isTicket=true;
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => TicketScreen(index: index)));
        }  else if (texto == 'Credito') {
          invoice.isCredit=true;
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProceeeCreditScreen(index: index)));
        } else if (texto == 'Peddler') {
          invoice.isPeddler=true;
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => PeddlersAddScreen(index: index)));
        }
        // Agrega más casos según necesites
      },
    ),
  );
}

Widget _getAdminMenu() {
    return SafeArea(
      child: Drawer(        
        backgroundColor: kColorFondoOscuro,
        child: ListView(
         itemExtent: 50,
          padding: EdgeInsets.zero,
          children: <Widget>[ const SizedBox(         
            height: 50,
            width: 120,         
            child: DrawerHeader(          
               margin: EdgeInsets.zero,
               padding: EdgeInsets.zero,
               decoration: BoxDecoration(               
               color: Color.fromARGB(255, 241, 244, 245), 
               image: DecorationImage(
                 scale: 5.5,
                 image:  AssetImage('assets/LogoSinFondo.png'))),
                   child: SizedBox()),
          ), 

         

            ListTile(
                textColor: kColorMenu,
              leading:   Container(
                width: 35,
                padding: EdgeInsets.all(getProportionateScreenWidth(4)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:  const Image(
                            image: AssetImage('assets/cbs.png'),
                            fit: BoxFit.contain,
                        ),
              ),  
              title: const Text('CashBacks'),
              onTap: () { 
                 Navigator.push(
                   context, 
                   MaterialPageRoute(
                     builder: (context) => CashbarksScreen(factura: widget.factura)
                   )
                 );
              },
            ),

              ListTile(
                 textColor: kColorMenu,
               leading:  Container(
                 width: 35,
                 padding: EdgeInsets.all(getProportionateScreenWidth(3)),
                 decoration:  BoxDecoration(
                   color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                 ),
                 child:  const Image(
                             image: AssetImage('assets/deposito.png'),
                         ),
               ),  
               title: const Text('Depositos'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) =>  DepositosScreen(factura: widget.factura)
                    )
                  );
               },
             ),

              ListTile(
              textColor:kColorMenu,
               leading:  Container(
                 width: 35,
                 padding: EdgeInsets.all(getProportionateScreenWidth(4)),
                 decoration: BoxDecoration(
                   color: const Color(0xFFF5F6F9),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child:  const Image(
                             image: AssetImage('assets/data.png'),
                         ),
               ),     
               title: const Text('Cierre Datafonos'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => CierreDatafonosScreen(factura: widget.factura)
                    )
                  );
               },
             ),

              ListTile(
                 textColor: kColorMenu,
                 leading:  Container(
                 width: 35,
                 padding: EdgeInsets.all(getProportionateScreenWidth(1)),
                 decoration: BoxDecoration(
                   color: kContrateFondoOscuro,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child:  const Image(
                             image: AssetImage('assets/viaticos.png'),
                         ),
               ),   
               title: const Text('Viaticos'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => ViaticosScreen(factura: widget.factura,)
                    )
                  );
               },
             ),

               ListTile(
                 textColor: kColorMenu,
                 leading: Container(
                   width: 35,
                   padding: EdgeInsets.all(getProportionateScreenWidth(2)),
                   decoration: BoxDecoration(
                     color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child:  const Image(
                               image: AssetImage('assets/peddler.png'),
                           ),
                 ),   
               title: const Text('Peddlers'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => PeddlersScreen(factura: widget.factura,)
                    )
                  ).then((value) {
                    //   _orderTransactions();
                   });
               },
             ),


            ListTile(
                 textColor: kColorMenu,
               leading: Container(
                   width: 35,
                   padding: EdgeInsets.all(getProportionateScreenWidth(2)),
                   decoration: BoxDecoration(
                     color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child:  const Image(
                               image: AssetImage('assets/NoTr.png'),
                           ),
                 ),   
               title: const Text('Transacciones'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const TransaccionesScreen()
                    )
                  );
               },
             ),

              ListTile(
                 textColor:kColorMenu,
               leading:  Container(
                   width: 35,
                   padding: EdgeInsets.all(getProportionateScreenWidth(2)),
                   decoration: BoxDecoration(
                     color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child:  const Image(
                               image: AssetImage('assets/tr9.png'),
                           ),
                 ),   
               title: const Text('Transferencias'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => TransferenciasScreen(factura: widget.factura)
                    )
                  );
               },
             ),

               ListTile(
               textColor:kColorMenu,
               leading: Container(
                   width: 35,
                   padding: EdgeInsets.all(getProportionateScreenWidth(4)),
                   decoration: BoxDecoration(
                     color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child:  const Image(
                               image: AssetImage('assets/sinpe.png'),
                           ),
                 ),   
               title: const Text('Sinpes'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => SinpesScreen(all: widget.factura)
                    )
                  );
               },
             ),

             ListTile(
                  textColor:kColorMenu,
               leading: Container(
                   width: 35,
                   padding: EdgeInsets.all(getProportionateScreenWidth(2)),
                   decoration: BoxDecoration(
                     color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child:  const Image(
                               image: AssetImage('assets/factura.png'),
                           ),
                 ),   
               title: const Text('Facturas Contado'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => FacturasScreen(factura: widget.factura, tipo: 'Contado',)
                    )
                  ).then((value) {
                    //   _orderTransactions();
                    
                   });
               },
             ),
              ListTile(
                   textColor: kColorMenu,
               leading:  Container(
                   width: 35,
                   padding: EdgeInsets.all(getProportionateScreenWidth(2)),
                   decoration: BoxDecoration(
                     color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child:  const Image(
                               image: AssetImage('assets/factura.png'),
                           ),
                 ),   
               title: const Text('Facturas Credito'),
               onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => FacturasScreen(factura: widget.factura,  tipo: 'Credito',)
                    )
                  ).then((value) {
                     //  _orderTransactions();
                   });
               },
             ),

              ListTile(
                  textColor: kColorMenu,
               leading: Container(
                   width: 35,
                   padding: EdgeInsets.all(getProportionateScreenWidth(2)),
                   decoration: BoxDecoration(
                     color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child:  const Image(
                               image: AssetImage('assets/printer.png'),
                               fit: BoxFit.contain,
                           ),
                 ),   
               title: const Text('Config Impresora'),
               onTap: () => { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const PrinterScreen()
                    )
                  ),
               },
             ),

                 ListTile(
                  textColor: kColorMenu,
               leading: Container(
                   width: 35,
                   padding: EdgeInsets.all(getProportionateScreenWidth(2)),
                   decoration: BoxDecoration(
                     color: kContrateFondoOscuro,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child:  const Image(
                               image: AssetImage('assets/cierre1.png'),
                               fit: BoxFit.contain,
                           ),
                 ),   
               title: const Text('Resumen Cierre'),
               onTap: () => { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) =>  ResumenCierre(factura: widget.factura,)
                    )
                  ),
               },
             ),


             ListTile(
                 textColor: kColorMenu,
              leading: Container(
                  width: 35,
                  padding: EdgeInsets.all(getProportionateScreenWidth(2)),
                  decoration: BoxDecoration(
                    color: kContrateFondoOscuro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:  const Image(
                              image: AssetImage('assets/salir.png'),
                              fit: BoxFit.contain,
                          ),
                ),   
              title: const Text('Cerrar Sesión'),
              onTap: () => { 
                 Navigator.pushReplacement(
                   context, 
                   MaterialPageRoute(
                     builder: (context) => const LoginScreen()
                   )
                 ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacturacionPage() {
  return Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 36, 37, 37),
        ),
        child: gridFacturacion(),
      ),
      Positioned(
        bottom: 15,
        left: 15,
        child: SizedBox(
          height: 56,
          width: 56,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShowProcessMenu(
                  cierreFinal: widget.factura.cierreActivo!.cierreFinal,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/AddTr.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
       Positioned(
        bottom: 15,
        right: 15,
        child: SizedBox(
          height: 56,
          width: 56,
          child: GestureDetector(
            onTap: () => _mostrarMenu(context,),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/backToCheck.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
      // Si quieres, mantén el FloatingActionButton...
    ],
  );
}

}