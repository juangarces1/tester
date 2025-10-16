
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tester/Components/cart_card.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/constans.dart';



class DetalleFacturaScreen extends StatefulWidget {
   final Factura factura;
 
   // ignore: use_key_in_widget_constructors
   const DetalleFacturaScreen({required this.factura});

  @override
  State<DetalleFacturaScreen> createState() => _DetalleFacturaScreenState();
}

class _DetalleFacturaScreenState extends State<DetalleFacturaScreen> {
  final bool _showLoader = false;  
  @override
  Widget build(BuildContext context) {
    return   SafeArea(
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: kBlueColorLogo,
          title: Text(widget.factura.nFactura, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.white),),
        ),
        body: Container(
          color: kColorFondoOscuro,
          child: Center(
            child: _showLoader 
              ? const LoaderComponent(loadingText: 'Por favor espere...',) 
              : _getContent(),
          ),
        ),      
       
      ),
    );
  }

   Widget _getContent() {
    return Container(
      color: const Color.fromARGB(255, 243, 239, 239),
      child: Column(
        children: <Widget>[          
          const SizedBox(height: 5,),     
          _showHeader(),
          const SizedBox(height: 5,),    
         widget.factura.detalles.isEmpty
          ? Container() 
          : const Text('Detalle de la Factura',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          Expanded(
            child: widget.factura.detalles.isEmpty ? _noContent() : _getProducts(),
          ),
        ],
      ),
    );
  }

    _showHeader() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        color: kColorFondoOscuro,
         shadowColor: const Color.fromARGB(255, 0, 2, 3),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(        
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(5),
           
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget> [ 
                const Center(child: Text('Info Factura', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,color: Colors.white),)),
                const SizedBox(height: 5,),
                Row(                        
                  children: [                          
                    const Text(
                      'Cliente: ', 
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5E8EC),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.factura.cliente, 
                        style: const TextStyle(
                          fontSize: 14,                      
                          color: Color(0xFFE5E8EC),
                        ),
                      ),
                    ),
                    
                  ],
                ),
                const SizedBox(height: 5,),
                
                  Row(                        
                  children: [                          
                    const Text(
                      'Email: ', 
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5E8EC),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.factura.email??'', 
                        style: const TextStyle(
                          fontSize: 14,                      
                          color: Color(0xFFE5E8EC),
                        ),
                      ),
                    ),
                    
                  ],
                ),
                const SizedBox(height: 5,),
                Row(
                  
                  children: [
                    const Text(
                      'Fecha: ', 
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                           color: Color(0xFFE5E8EC),
                      ),
                    ),
                    Text(
                     DateFormat.yMd().add_jm().format(widget.factura.fechaHoraTrans),    
                      style: const TextStyle(
                        fontSize: 14,
                         color: Color(0xFFE5E8EC),
                      ),
                    ),
                    
                  ],
                ),
                const SizedBox(height: 5,),
                Row(                        
                  children: [
                    const Text(
                      'Kilometraje: ', 
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                           color: Color(0xFFE5E8EC),
                      ),
                    ),
                    Text(
                     widget.factura.kilometraje.toString(), 
                      style: const TextStyle(
                        fontSize: 14,
                         color: Color(0xFFE5E8EC),
                      ),
                    ),                          
                  ],
                ),
                const SizedBox(height: 5,),
                Row(                        
                  children: [
                    const Text(
                      'Placa: ', 
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                           color: Color(0xFFE5E8EC),
                      ),
                    ),
                    Text(
                      widget.factura.nPlaca.toString(), 
                      style: const TextStyle(
                        fontSize: 14,
                         color: Color(0xFFE5E8EC),
                      ),
                    ),                          
                  ],
                ),
                const SizedBox(height: 5,),
                Row(                         
                  children: [
                    const Text(
                      'Impuesto: ', 
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                           color: Color(0xFFE5E8EC),
                      ),
                    ),
                    Text(
                    NumberFormat.currency(symbol: '¢').format(widget.factura.totalImpuesto), 
                      style: const TextStyle(
                        fontSize: 14,
                         color: Color(0xFFE5E8EC),
                      ),
                    ),                          
                  ],
                ),
                const SizedBox(height: 5,),
                Row(                        
                  children: [
                    const Text(
                      'Total: ', 
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                           color: Color(0xFFE5E8EC),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '¢').format(widget.factura.totalFactura),
                      style: const TextStyle(
                        fontSize: 14,
                         color: Color(0xFFE5E8EC),
                      ),
                    ),                          
                  ],
                ),              
              
               
              ],
            ),
          ),
        ),
      ),
    );
  }


   Widget _noContent() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: const Text(          
           'No hay detalle registrado.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  Widget _getProducts() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
       
        decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromARGB(255, 136, 133, 133),
              width: 2.0,
              style: BorderStyle.solid
            ),
            borderRadius: BorderRadius.circular(20),
            color: kColorFondoOscuro
          ),
        padding: const EdgeInsets.all(10),
       
        child: ListView.builder(
          itemCount: widget.factura.detalles.length,
          itemBuilder: (context, index) {
           return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: 
             CartCard(product: widget.factura.detalles[index],)
           );  
          },    
        ),
      ),
    );
  }         
}