
import 'package:tester/Models/FuelRed/product.dart';

class Factura {
  String cliente='';
  String nFactura='';
  String? codigoCliente;
  String? descripCliente;
  DateTime? fechaFactura;
  DateTime fechaHoraTrans = DateTime.now();
  String? tipoDocumento;
  String? email;
  String? nPlaca;
  String? observaciones;
  String? clave;
  double? totalGravado;
  double? totalFactura;
  double? totalImpuesto;
  double? totalDescuento;
  double? totalExento;
  double? kilometraje;  
  int? plazo;
  String? employeeID;
  List<Product> detalles = [];
  double? montoFactura;
  String? usuario;
  String? identificacion;
  String? telefono;
  bool isDevolucion = false;
  bool isFactura = false;
  bool  isTicket = false;
  bool isCredito = false;
  double? saldo; 
  int? diasEnMora;
  
  Factura(
  {    
    required this.cliente,
    required this.nFactura,
    this.codigoCliente,
    this.descripCliente,
    this.fechaFactura,
    required this.fechaHoraTrans,
    this.tipoDocumento,
    this.email,
    this.nPlaca,
    this.observaciones,
    this.clave,
    this.totalGravado,
    this.totalFactura,
    this.totalImpuesto,
    this.totalDescuento,
    this.totalExento,
    this.kilometraje,        
    this.plazo,
    this.employeeID,
    required this.detalles,
    this.montoFactura,
    this.usuario,
    this.identificacion,
    this.telefono,
    this.saldo,
    this.diasEnMora,
    
  }){
  // Asignar valores a isDevolucion, isFactura e isTicket basados en el valor de nFactura
  if (nFactura.startsWith('6')) {
    isDevolucion = true;
  } else if (nFactura.startsWith('7') || nFactura.startsWith('8')) {
    isFactura = true;
  } else if (nFactura.startsWith('2') || nFactura.startsWith('9')) {
    isTicket = true;
  }
  if (plazo != null && plazo! > 0){
     isCredito = true;
  }
}
  
  

  Factura.fromJson(Map<String, dynamic> json) {
    cliente =  json['descripCliente'] ?? '';
    nFactura = json['nFactura'];
    codigoCliente = json['codigoCliente'];
    descripCliente = json['descripCliente'];
    fechaFactura = json['fechaFactura'] != null ? DateTime.parse(json['fechaFactura']) : null;
    fechaHoraTrans =  DateTime.parse(json['fechaHoraTrans']); 
    tipoDocumento = json['tipoDocumento'];
    email = json['email'];
    nPlaca = json['nPlaca'];
    observaciones = json['observaciones'];
    clave = json['clave'];
    totalGravado = json['totalGravado'];
    totalFactura = json['totalFactura'];
    totalImpuesto = json['totalImpuesto'];
    totalDescuento = json['totalDescuento'];
    totalExento = json['totalExento'];
    kilometraje = json['kilometraje'];   
    plazo = json['plazo'];
    employeeID = json['msgDetalle1'];
     if (json['detalles'] != null) {
      detalles = [];
      json['detalles'].forEach((d) {
        detalles.add(Product.fromJson(d));
      });
    }
    montoFactura = json['montoFactura'];
    identificacion = json['cedulaCliente'];
    telefono = json['telefono01Cliente'];
    if (nFactura.startsWith('6')) {
      isDevolucion = true;
    } else if (nFactura.startsWith('7') || nFactura.startsWith('8')) {
      isFactura = true;
    } else if (nFactura.startsWith('2') || nFactura.startsWith('9')) {
      isTicket = true;
    }
    if(plazo! > 0){
      isCredito = true;
    }
    if(json['totalTip'] != null){
      saldo = json['totalTip'];
    } else {
      saldo = 0;
    }
    diasEnMora = json['diasEnMora'];
    
  } 

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['nFactura'] = nFactura;
    data['codigoCliente'] = codigoCliente;
    data['descripCliente'] = descripCliente;
    data['fechaFactura'] = fechaFactura;
    data['fechaHoraTrans'] = fechaHoraTrans;
    data['tipoDocumento'] = tipoDocumento;
    data['email'] = email;
    data['nPlaca'] = nPlaca;
    data['observaciones'] = observaciones;
    data['clave'] = clave;
    data['totalGravado'] = totalGravado;
    data['totalFactura'] = totalFactura;
    data['totalImpuesto'] = totalImpuesto;
    data['totalDescuento'] = totalDescuento;
    data['totalExento'] = totalExento;
    data['kilometraje'] = kilometraje;   
    data['plazo'] = plazo;
    data['msgDetalle1'] = employeeID;
    data['detalles'] = detalles.map((d) => d.toJson()).toList();
    data['montoFactura'] = montoFactura;
    data['usuario'] = usuario;
    data['identificacion'] = identificacion;
    data['telefono'] = telefono;

    return data;
  }


  

}