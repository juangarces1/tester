
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/tranferview.dart';
import 'package:tester/Models/transparcial.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';
import 'package:provider/provider.dart';



class TransferScreen extends StatefulWidget {

  final int index; 
 
  // ignore: use_key_in_widget_constructors
  const TransferScreen({
     required this.index,     
 
   });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

 class _TransferScreenState extends State<TransferScreen> with SingleTickerProviderStateMixin {
  List<Transferview> _transfers =[];
  final List<Transferview> _transferenciasAux =[];
  late TabController _tabController;
  late Invoice factura;
  bool _showLoader = false;
  final bool _isFiltered = false;
  bool showTransfer = true;


  @override
  void initState() {
    super.initState();
      _tabController = TabController(length: 2, vsync: this);
       factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    _getTransfers();
   // setUpTransfer();
  }

   @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
 @override
 Widget build(BuildContext context) {  
  Invoice facturaT = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    return SafeArea(
      child: Scaffold(
        backgroundColor: kContrateFondoOscuro,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: appBar1(facturaT),
        ),
        body:  TabBarView(
          controller: _tabController,
          children: [            
            _getContent(),
            _getSelected(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kContrateFondoOscuro,
          child:  Container(
            padding: const EdgeInsets.all(4),
            child: Image.asset('assets/backToCheck.png')),
          onPressed: () => _goAdd(),
        ),    
       
              
      ),
    );
  }
 
 Widget appBar1(Invoice facturaT) {
  return Center(
  child: Container(
    width: double.infinity,
    color: kBlueColorLogo,
    child: Column(
    
      children: [
         const SizedBox(height: 10,),
        Row(          
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 10,),
            _buildBackButton(),
            const Spacer(),
            _buildTransferInfo(facturaT),
          ],
        ),
        _buildTabBar(),
      ],
    ),
  ),
  );
 }

 Widget _buildBackButton() {
  return SizedBox(
    height: getProportionateScreenWidth(40),
    width: getProportionateScreenWidth(40),
    child: TextButton(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(60),
        ),
        backgroundColor: const Color.fromARGB(255, 231, 225, 225),
        padding: EdgeInsets.zero,
      ),
      onPressed: () => _goBack(),  
      child: SvgPicture.asset(
        "assets/Back ICon.svg",
        height: 15,
        // ignore: deprecated_member_use
        color: kPrimaryColor,
      ),
    ),
  );
}

Widget _buildTransferInfo(Invoice facturaT) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      color: kBlueColorLogo,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [          
        Text(
          'Transferencias(${facturaT.formPago!.transfer.transfers.length})',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          'Saldo: ${NumberFormat("#,##0", "en_US").format(facturaT.formPago!.transfer.saldoActual)}',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),                                   
      ],
    ),
  );
}

Widget _buildTabBar() {
  return Container(
    color: const Color.fromARGB(255, 6, 66, 114),
    margin: const EdgeInsets.only(top: 10),
    width: double.infinity,
    child: TabBar(
      indicatorColor: Colors.white,
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: 'Transferencias'),
        Tab(text: 'Seleccionadas'),
      ],
    ),
  );
}

 void _goBack() async {
   Navigator.pop(context);
    
  }

 Future<void> _getTransfers() async {
    setState(() {
      _showLoader = true;
    });

   
    Response response = await ApiHelper.getTransfes();

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
      _transfers = response.result;
    });
    setUpTransfer();
  }

 Widget _getContent() {
    return _transfers.isEmpty 
      ? _noContent()
      : newContent();
  }

 Widget _noContent() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Text(
          _isFiltered
          ? 'No hay transferencias con ese criterio de búsqueda.'
          : 'No hay transferencias registradas.',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

 Widget _getContentTP() {
    return factura.formPago!.transfer.transfers.isEmpty 
      ? _noContentTp()
      : _parcialTransferList();
  }

 Widget _noContentTp() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: const Text(        
         
          'No hay transferencias Seleccionadas.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

 Widget _getListView() {
    return RefreshIndicator(
      onRefresh: _getTransfers,
      child: ListView(
        children: _transfers.map((e) {
          return Padding(
            padding: const EdgeInsets.only(right: 5, left: 5, bottom: 5),
            child: Card(

               color:  const Color.fromARGB(255, 222, 225, 233),
                    shadowColor: const Color.fromARGB(255, 16, 38, 54),
                    elevation: 7,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
              child: InkWell(
                onTap: () => _addTRansfer(e),
                child: Container(
                  margin: const EdgeInsets.all(5),
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [                    
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.cliente, 
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                 
                                    Text(
                                      'Deposito: ${e.numeroDeposito}', 
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54
                                      ),
                                    ),
                                 
                                    Text(
                                     'Monto: ¢ ${NumberFormat("#,##0", "en_US").format(e.monto)}', 
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                         color:  Colors.black54
                                      ),
                                    ),
                                  
                                    Text(
                                        'Saldo: ¢ ${NumberFormat("#,##0", "en_US").format(e.saldo)}', 
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                         color: kPrimaryColor
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
 
 Widget cardTranser(TransParcial tr) {
    return Card( 
      color:  const Color.fromARGB(255, 222, 225, 233),
      shadowColor: const Color.fromARGB(255, 16, 38, 54),
      elevation: 7,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [                    
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.cliente, 
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        
                          Text(
                            'Deposito: ${tr.numeroDeposito}', 
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54
                            ),
                          ),
                        
                          Text(
                           'Aplicado: ¢ ${NumberFormat("#,##0", "en_US").format(tr.aplicado)}', 
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                               color: Colors.black54
                            ),
                          ),
                       
                          Text(
                              'Saldo: ¢ ${NumberFormat("#,##0", "en_US").format(tr.saldo)}', 
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                               color: kPrimaryColor
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
           
          ],
        ),
      ),

    );
  }

 Widget _parcialTransferList() {
    return  Padding(
        padding:
        EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
        child: 
        ListView.builder(
          itemCount: factura.formPago!.transfer.transfers.length,
          itemBuilder: (context, index) {
            final item = factura.formPago!.transfer.transfers[index].numeroDeposito;
           return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Dismissible(
              key: Key(item),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {              
                setState(() {               
                  _transfers.add(_transferenciasAux[index]);
                  
                
                  factura.formPago!.transfer.transfers.removeAt(index);
                  _transferenciasAux.removeAt(index);
                  FacturaService.updateFactura(context,factura);
                  // factura.setSaldo();
                  // navigate to the second tab
                   orderTransfer();
                  _tabController.animateTo(0);
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
              child: cardTranser(factura.formPago!.transfer.transfers[index]),
              
            ),
           );  
          },    
        ),
        );
  }
 
 void _addTRansfer(Transferview e) async {
    if (factura.formPago!.transfer.saldoActual <= 0){
       Fluttertoast.showToast(
            msg: "No hay saldo para agregar transferencias",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color.fromARGB(255, 215, 27, 17),
            textColor: Colors.white,
            fontSize: 16.0
          ); 
      
      return;
    }

    if (!IsClientRigth(e)){
       Fluttertoast.showToast(
            msg: "Seleccione transferencias del mismo cliente",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color.fromARGB(255, 215, 27, 17),
            textColor: Colors.white,
            fontSize: 16.0
          ); 
      
      return;
    }
    double saldoFactura = factura.formPago!.transfer.saldoActual;
    double saldoTr = e.saldo.toDouble();
    double cd = saldoTr - saldoFactura;
    double apli = 0;
    double resto = 0;
    if (cd > 0) {
       apli=saldoFactura; 
       resto=cd;
    } else {
      apli = saldoTr;
      resto=0;
    }
    //Creamos la transferencia parcial
    TransParcial transParcial = TransParcial(
      id: e.id,
      saldo: resto.toInt(),
      aplicado: apli.toInt(),
      cuenta: e.cuenta,
      numeroDeposito: e.numeroDeposito,
      cliente: e.cliente
    );
   
  

   
   

    
    setState(() {
   
        //Agregamos la tranferencia parcial a la lista de transferencias parciales
         factura.formPago!.transfer.transfers.add(transParcial);
       FacturaService.updateFactura(context, factura);
      _transferenciasAux.add(e);
      //Removemos la transferencia de la lista de transferencias
      _transfers.remove(e);
       //navigate to the second tab
      _tabController.animateTo(1);
    });
    
  }

  // ignore: non_constant_identifier_names
 bool IsClientRigth(Transferview trans){
      if (factura.formPago!.transfer.transfers.isEmpty){
         return true;
      }
      else {
        if (factura.formPago!.transfer.transfers.last.cliente != trans.cliente){
          return false;
        }
      }


      return true;
  }

 void _goAdd() async {

     if (factura.formPago!.transfer.transfers.isEmpty){
       Fluttertoast.showToast(
            msg: "Seleccione al menos una transferencia",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color.fromARGB(255, 207, 10, 10),
            textColor: Colors.white,
            fontSize: 16.0
          );  
       return;
     }
   

        if (isNearZero(factura.formPago!.transfer.saldoActual)){
             factura.formPago!.totalTransfer = factura.saldo;
        } else {
           factura.formPago!.totalTransfer =  factura.formPago!.transfer.totalAplicado;
        }
     // factura.formPago!.totalTransfer=1000;
      FacturaService.updateFactura(context, factura);
        
        
          
     

   
      Navigator.pop(context);


  }
bool isNearZero(double value, {double minRange = 0.1, double maxRange = 1.0}) {
  // Verifica que el valor absoluto esté dentro del rango especificado
   return value > 0 && value <= 0.2;
}


  
 Widget newContent() {   
    return Stack(
      children: [
        Container(
          child:  _getListView(),
        ),

        _showLoader ? const LoaderComponent(loadingText: 'Cargando...') : Container(),
      ],
    );
  }
 
  void orderTransfer() {
    _transfers.sort((a, b) {
      return a.cliente.compareTo(b.cliente);
    });
  }
 
 void setUpTransfer() {
   for (var element in factura.formPago!.transfer.transfers) {
     Transferview transferview = Transferview(
       id: element.id,
       saldo: element.saldo,
       cuenta: element.cuenta,
       numeroDeposito: element.numeroDeposito,
       cliente: element.cliente,
       monto: element.saldo,
     );
     _transferenciasAux.add(transferview);

     //search and remove from _transfers where numerodeposito = element.numerodeposito
     if(_transfers.isNotEmpty){
        Transferview tr = _transfers.firstWhere((elemento) => elemento.numeroDeposito == transferview.numeroDeposito);
       _transfers.remove(tr);
     }
    
   }
  }
  
  _getSelected() {
    return Container(
      child: _getContentTP(),
    );
  }

}