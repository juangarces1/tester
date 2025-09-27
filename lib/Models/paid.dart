
import 'package:tester/Models/cliente.dart';

import 'package:tester/Models/sinpe.dart';
import 'package:tester/Models/transferencia.dart';
import 'package:tester/helpers/varios_helpers.dart';


class Paid { 
  double totalEfectivo = 0; 
  double totalBac = 0; 
  double totalDav = 0; 
  double totalBn = 0; 
  double totalSctia = 0; 
  double totalDollars = 0; 
  double totalCheques = 0; 
  double totalCupones = 0; 
  double totalPuntos = 0; 
  double totalTransfer = 0;
  double totalSinpe = 0;  
  String codigoTipoID = '';  
  String email = ''; 
  bool showTotal=false;  
  bool showFact=false;
  Cliente clienteCredito = Cliente(
    placas: [],
     nombre: "",
      documento: "",
      codigoTipoID: "",
      email: "",
      tipo: "",
      codigo: '',
      puntos: 0,
      telefono: ""

    
  );

  
  Cliente clienteFactura = Cliente(
      nombre: "",
      documento: "",
      codigoTipoID: "",
      email: "",
      puntos: 0,
       codigo: '',
        telefono: '',
    );
    Cliente clientePuntos = Cliente(
      nombre: "",
      documento: "",
      codigoTipoID: "",
      email: "",
      puntos: 0,
       codigo: '',
        telefono: '',
    ); 
  Sinpe sinpe = Sinpe(
      id: 0,
      numComprobante: '',
      nota: '',
      idCierre: 0,
      nombreEmpleado: '',
      fecha: DateTime.now(),
      numFact: '',
      activo: 0,
      monto: 0,
    );
  Transferencia transfer = Transferencia(
    cliente: Cliente(
      nombre: "",
      documento: "",
      codigoTipoID: "",
      email: "",
      puntos: 0,
      codigo: '',
      telefono: '',
    ),
     transfers: [],
      monto: 0, 
      totalTransfer: 0
  ); 
  
  Paid({
    required this.totalEfectivo,
    required this.totalBac,   
    required this.totalDav,
    required this.totalBn,    
    required this.totalSctia,   
    required this.totalDollars,
    required this.totalCheques,
    required this.totalCupones,   
    required this.totalPuntos,
    required this.totalTransfer,
  
    required this.clienteFactura,
    required this.transfer,
    required this.showTotal,
    required this.showFact,
    required this.totalSinpe,
    required this.sinpe,
    required this.clientePuntos,

  });

  Paid.fromJson(Map<String, dynamic> json) {  
    totalEfectivo = json['totalEfectivo'];
    totalBac = json['totalBac'];  
    totalDav = json['totalDav'];
    totalBn = json['totalBn'];  
    totalSctia = json['totalSctia'];
    totalDollars = json['totalDollars'];  
    totalCheques = json['totalCheques'];
    totalPuntos = json['totalPuntos'];   
    totalTransfer = json['totalTransfer'];
   
    clienteFactura= Cliente.fromJson(json['clienteFactura']);
     clientePuntos= Cliente.fromJson(json['clientePuntos']);
    transfer= Transferencia.fromJson(json['transfer']);
    sinpe = Sinpe.fromJson(json['sinpe']);
    totalSinpe = json['totalSinpe'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};   
    data['totalEfectivo'] = totalEfectivo;  
    data['totalBac'] = totalBac;
    data['totalDav'] = totalDav;   
    data['totalBn'] = totalBn;
    data['totalSctia'] = totalSctia;  
    data['totalDollars'] = totalDollars;
    data['totalCheques'] = totalCheques;   
    data['totalPuntos'] = totalPuntos;
    data['totalTransfer'] = totalTransfer;   
   
    data['clientePuntos'] = clientePuntos.toJson();
     data['clienteFactura'] = clienteFactura.toJson();
    data['totalTransfer'] = transfer.toJson();
    data['sinpe'] = sinpe.toJson();
    data['totalSinpe'] = totalSinpe;
    return data;
  }
  
   String get monedaEfectivo {
    return VariosHelpers.formattedToCurrencyValue(totalEfectivo.toString());
   }
    String get monedaBac {
    return VariosHelpers.formattedToCurrencyValue(totalBac.toString());
   }
    String get monedaDav {
    return VariosHelpers.formattedToCurrencyValue(totalDav.toString());
   }
    String get monedaBn {
    return VariosHelpers.formattedToCurrencyValue(totalBn.toString());
   }
    String get monedaSctia {
    return VariosHelpers.formattedToCurrencyValue(totalSctia.toString());
   }
    String get monedaDollar {
    return VariosHelpers.formattedToCurrencyValue(totalDollars.toString());
   }
    String get monedaCheque {
    return VariosHelpers.formattedToCurrencyValue(totalCheques.toString());
   }
    String get monedaPuntos {
    return VariosHelpers.formattedToCurrencyValue(totalPuntos.toString());
   }
    String get monedaTransfer {
    return VariosHelpers.formattedToCurrencyValue(totalTransfer.toString());
   }
    String get monedaSinpe {
    return VariosHelpers.formattedToCurrencyValue(totalSinpe.toString());
   }
    String get monedaCupones {
    return VariosHelpers.formattedToCurrencyValue(totalCupones.toString());
   }

 
}