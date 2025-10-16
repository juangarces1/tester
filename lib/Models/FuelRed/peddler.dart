

import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Models/FuelRed/empleado.dart';
import 'package:tester/Models/FuelRed/product.dart';

class Peddler {
  int? id;
  Cliente? cliente;
  String? fecha;
  bool? estado;
  int? idcierre;
  Empleado? pistero;  
  String? placa;
  String? km;
  String? observaciones;
  String? chofer;
  String? numFact;
  List<Product>? products;
  String? orden;
  
  Peddler(
      {this.id,     
      this.cliente,
      this.fecha,
      this.estado,
      this.idcierre,
      this.pistero,     
      this.placa,
      this.km,
      this.observaciones,
      this.chofer,
      this.numFact,
      this.products,
      this.orden,
      });

    double get total {
    if (products == null) {
      return 0.0;
    }
    return products!.fold(0.0, (total, p) => total + (p.total));
  }


  Peddler.fromJson(Map<String, dynamic> json) {
    id = json['id'];    
    fecha = json['fecha'];
    estado = json['estado'];
    idcierre = json['idcierre'];  
    pistero = Empleado.fromJson(json['pistero']); 
    placa = json['placa'];
    km = json['kms'];
    observaciones = json['observaciones'];
    chofer = json['chofer'];
    numFact = json['numFact'];
    cliente = Cliente.fromJson(json['cliente']);
    products = json['products'] != null
        ? (json['products'] as List).map((i) => Product.fromJson(i)).toList()
        : null;
    orden = json['orden'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};   
    data['idcierre'] = idcierre;  
    data['placa'] = placa;
    data['kms'] = km;
    data['observaciones'] = observaciones;
    data['chofer'] = chofer;   
    data['cliente'] = cliente!.toJson();
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    data['pistero'] = pistero!.toJson();
    data['orden'] = orden;
    return data;
  }

  factory Peddler.empty() => Peddler(
        id: 0,
        cliente: null,          // así evitas asumir constructores de Cliente/Empleado
        fecha: null,
        estado: false,
        idcierre: null,
        pistero: null,
        placa: '',
        km: '',
        observaciones: '',
        chofer: '',
        numFact: '',
        products: <Product>[],
        orden: '',
      );
}