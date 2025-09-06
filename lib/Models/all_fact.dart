import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/cart.dart';
import 'package:tester/Models/cierreactivo.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/clientecredito.dart';


import 'package:tester/Models/product.dart';



class AllFact {
  Cart? cart;
  List<Product> transacciones = [];
  List<Product> productos = [];
  String? placa;
  int? kms;  
  int lasTr=0;
  CierreActivo? cierreActivo;
  List<Cliente> clientesFacturacion = [];
  List<ClienteCredito> clientesCredito = [];
  List<ClientePromo> clientesPromo  = [];
  List<Invoice> invoices = [];

  AllFact({
    this.cart,
    this.transacciones = const [],
    this.productos = const [],
    this.placa,
    this.kms,
    required this.lasTr,
    this.cierreActivo,
    this.clientesFacturacion = const [],
    this.clientesCredito = const [],
    this.clientesPromo=const [],
    this.invoices=const [],

  });

  factory AllFact.fromJson(Map<String, dynamic> json) {
    return AllFact(
      cart: null,
      transacciones: json['transacciones'] != null ? (json['transacciones'] as List).map((i) => Product.fromJson(i)).toList() : [],
      productos: json['productos'] != null ? (json['productos'] as List).map((i) => Product.fromJson(i)).toList() : [],
      placa: '',
      kms: 0,
      lasTr: 0, 
      clientesPromo: json['clientesPromo'] != null 
        ? (json['clientesPromo'] as List)
            .map((i) => ClientePromo.fromJson(i))
            .toList()
        : [], // Esto manejará los valores nulos correctamente
      clientesFacturacion: json['clientesFacturacion'] != null 
        ? (json['clientesFacturacion'] as List)
            .map((i) => Cliente.fromJson(i))
            .toList()
        : [], // Esto manejará los valores nulos correctamente
      clientesCredito: json['clientesCredito'] != null ? (json['clientesCredito'] as List).map((i) => ClienteCredito.fromJson(i)).toList() : [],
        cierreActivo: json['cierreActivo'] != null ? CierreActivo.fromJson(json['cierreActivo']) : null, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart': cart,
      'transacciones': transacciones.map((i) => i.toJson()).toList(),
      'productos': productos.map((i) => i.toJson()).toList(),
      'placa': placa,
      'kms': kms,
      'lasTr': lasTr,
    
      'cierreActivo': cierreActivo?.toJson(),
   
      'clientesFacturacion': clientesFacturacion.map((i) => i.toJson()).toList(),
    };
  }

     void actualizarCantidadProductos(List<Product> ventas) {
      for (var prodCarro in ventas) {
        if (prodCarro.unidad != "L") {
          // Busca el producto en la lista de productos y actualiza su cantidad
          for (var prod in productos) {
            if (prod.codigoArticulo == prodCarro.codigoArticulo) {
              prod.cantidad = 0;
              break; // Detiene la búsqueda una vez que encuentra el producto
            }
          }
        }
      }
  }


 
}
