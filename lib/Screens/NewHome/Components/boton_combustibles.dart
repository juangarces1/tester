import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

import '../../../Models/response.dart';

class BotonTransacciones extends StatefulWidget {
  
  final String imagePath;
   final Function(Product) onItemSelected;
    final int zona;
  const BotonTransacciones({
    super.key,  
    required this.imagePath,  
    required this.onItemSelected,
    required this.zona,
    });

  @override
  State<BotonTransacciones> createState() => _BotonTransaccionesState();
}



class _BotonTransaccionesState extends State<BotonTransacciones> {
 
  List<Product> transacciones = [];
  bool showLoader = false;

  @override
  void initState() {
  
    super.initState();
    _updateTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: 56,
      child: GestureDetector(
            onTap: () => _showModal(context),
            child: ClipRRect(
      borderRadius: BorderRadius.circular(5), // Borde semicurvo para la imagen
      child: Image.asset(
        widget.imagePath,
        fit: BoxFit.cover, // Ajusta la imagen para que llene el contenedor
      ),
            ),
      ),
    );
}

  void _showModal(BuildContext context) async {
   await _updateTransactions();
     if (!mounted) return; 
    showModalBottomSheet(      
      context: context,
      builder: (BuildContext context) {       
            return transacciones.isNotEmpty ?  Container(
              color: kColorFondoOscuro,
              child: Padding(
               padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
               child: RefreshIndicator(
                 onRefresh: () async {
                   _updateTransactions();
                 },
                 child: GridView.builder(
                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                     crossAxisCount: 2, // Número de columnas
                     crossAxisSpacing: 10, // Espaciado horizontal entre los elementos
                     mainAxisSpacing: 10, // Espaciado vertical entre los elementos
                   ),
                   itemCount: transacciones.length,
                   itemBuilder: (context, indice) {
                     return buildCard(product: transacciones[indice]);
                   },
                 ),
               ),
              ),
            ) : _noTr();
          },
        );      
  }

  Widget _noTr(){
  return Container(
      color: kColorFondoOscuro,
    child: Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            Center(
              child: Container(
                padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                height: 100,
                width: 100,
                color: kColorFondoOscuro,
                child: AspectRatio(
                    aspectRatio: 1,
                    child: InkWell(
                      onTap: () => _updateTransactions(),
                      child: Container(
                          padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                          decoration: BoxDecoration(
                          color: kSecondaryColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(15),
                          ),
                          child:  const Image(
                                image: AssetImage('assets/NoTr.png'),
                                fit: BoxFit.cover,
                                height: 70,
                                width: 70,
                              ),                         
                      ),
                    ),
                  ),
                          
                  
              ),
            ),
            Center(
              child: Text(
                'No Hay Transacciones',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(18),
                  fontWeight: FontWeight.bold,
                  color: kContrateFondoOscuro,
                ),
              ),),
             
             
          ],
        
        ),
           showLoader ? const CircularProgressIndicator() : Container(),
      ],
    ),
  );
 }

  Widget buildCard({
  required Product product
  }) => Stack(
    children: [
      Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(10)),
        decoration: BoxDecoration(
          color: VariosHelpers.getShadedColor(product.cantidad.toString(),  Colors.black),
          borderRadius: BorderRadius.circular(15),
        ),
       
        width: getProportionateScreenWidth(170),   
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [           
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Material(                
                 color: VariosHelpers.getShadedColor(product.cantidad.toString(), Colors.black),
                  child: Ink.image(                        
                    image: product.detalle =='Super' ?  const AssetImage('assets/super.png') : 
                      product.detalle=='Regular' ? const AssetImage('assets/regular.png') : 
                      product.detalle=='Exonerado' ? const AssetImage('assets/exonerado.png') :
                      const AssetImage('assets/diesel.png'),
                      fit: BoxFit.cover,
                      child: InkWell(
                           onTap: () {
                              widget.onItemSelected(product); 
                               Navigator.of(context).pop();// Llama a la función pasando el producto
                            },
                      ),
                    ),
                  ),
                ),
              ),
              Text(
              "Disp: ${product.dispensador.toString()}",
              style: TextStyle(
                fontSize: getProportionateScreenWidth(16),
                fontWeight: FontWeight.normal,
                color:Colors.white,
              ),
            ),       
                 
          Text(
            "Cant: ${product.cantidad.toString()}",
            style: TextStyle(
              fontSize: getProportionateScreenWidth(16),
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),
          Text(
            "¢${NumberFormat("###,000", "en_US").format(product.total.toInt())}",
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
                color: const Color.fromARGB(255, 36, 35, 35).withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1), // Cambios en la sombra
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.list_alt_outlined, color: Colors.white), // Ajusta color y tamaño según necesidad
            onPressed: () {
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
              // testPrint.printTransaccion(product);
            },
          ),
        ),
      ),

    ],
  );
  
     Future<void> _updateTransactions() async {
      setState(() {
        showLoader =true;
      });
      Response rsponseTransacciones = await ApiHelper.getTransaccionesAsProduct(widget.zona);    
       setState(() {
        showLoader =false;
      }); 
      List<Invoice> facturas = [];
      if(mounted){
        facturas  =  Provider.of<FacturasProvider>(context, listen: false).facturas;
      }
      
      if (rsponseTransacciones.isSuccess){
         setState(() {
          transacciones = rsponseTransacciones.result; 
          transacciones = filtrarProductosNoEnFacturas(transacciones, facturas);
        });   
      } 
      
     }

     List<Product> filtrarProductosNoEnFacturas(List<Product> productosABuscar, List<Invoice> facturas) {
  // Crear una nueva lista que será la que se retorne
  List<Product> productosFiltrados = List<Product>.from(productosABuscar);
      for (var factura in facturas) {
        if (factura.detail != null) {
          for (var productoFactura in factura.detail!) {
            // Eliminar el producto de la lista filtrada si coincide con alguno de la factura
            productosFiltrados.removeWhere((productoABuscar) => productoABuscar.transaccion == productoFactura.transaccion);
          }
        }
      }
      return productosFiltrados;
    }

}



