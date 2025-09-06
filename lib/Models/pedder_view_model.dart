

import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/product.dart';

class PeddlerViewModel {
  int? id; 
  String? fecha;
  bool? estado;
  int? idcierre;
  String? pistero; 
  String? placa;
  String? km;
  String? observaciones;
  String? chofer; 
  String? orden; 
  List<Product>? products;
  Cliente? cliente;

  PeddlerViewModel(
      {this.id,   
      this.fecha,
      this.estado,
      this.idcierre,
      this.pistero,      
      this.placa,
      this.km,
      this.observaciones,
      this.chofer,     
      this.cliente,     
      this.orden,
      this.products,
    });

  PeddlerViewModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
   
    fecha = json['fecha'];
    estado = json['estado'];
    idcierre = json['idcierre'];
    pistero = json['pistero'];
    placa = json['placa'];
    km = json['km'];
    observaciones = json['observaciones'];
    chofer = json['chofer'];   
    cliente = Cliente.fromJson(json['cliente']); 
    orden = json['orden'];
    products = json['products'] != null
        ? (json['products'] as List).map((i) => Product.fromJson(i)).toList()
        : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;   
    data['fecha'] = fecha;
    data['estado'] = estado;
    data['idcierre'] = idcierre;
    data['placa'] = placa;
    data['km'] = km;
    data['observaciones'] = observaciones;
    data['chofer'] = chofer;

    return data;
  }

  //make the method to pass form Peddler to PeddlerViewModel
      
}