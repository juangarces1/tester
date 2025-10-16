import 'package:tester/Models/FuelRed/articulo_venta.dart';
import 'package:tester/Models/FuelRed/calibracion.dart';
import 'package:tester/Models/FuelRed/cashback.dart';
import 'package:tester/Models/FuelRed/cierreactivo.dart';
import 'package:tester/Models/FuelRed/cierredatafono.dart';
import 'package:tester/Models/FuelRed/deposito.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/Models/FuelRed/linea_inventario.dart';
import 'package:tester/Models/FuelRed/peddler.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/Models/FuelRed/tarjeta.dart';
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/Models/FuelRed/transparcial.dart';
import 'package:tester/Models/FuelRed/viatico.dart';

class CierreCajaGeneral {

 
  CierreActivo? cierre;  
  List<Deposito>? depositos;
  List<Factura>? facturas;
  List<Calibracion>? calibraciones;
  List<Cashback>? cashbacks;
  List<Tarjeta>? tarjetas;
  List<CierreDatafono>? cierresDatafono;
  List<TransParcial>? transferencias;
  List<Viatico>? viaticos;
  List<ArticuloVenta>? articulosVenta;
  List<Transaccion>? transacciones;
  List<LineaInventario>? inventariofinal;
  List<Peddler>? peddlers;
  List<Sinpe>? sinpes;



  CierreCajaGeneral({
    
      this.cierre,     
      this.depositos,
      this.facturas,
      this.calibraciones,
      this.cashbacks,
      this.tarjetas,
      this.cierresDatafono,
      this.transferencias,
      this.viaticos,
      this.articulosVenta,
      this.transacciones,
      this.inventariofinal,
      this.peddlers,
      this.sinpes,

  });

  double get totalSinpes {
    if (sinpes == null) {
      return 0.0;
    }
    return sinpes!.fold(0.0, (total, s) => total + (s.monto));
  }

   double get totalTransacciones {
    if (transacciones == null) {
      return 0.0;
    }
    return transacciones!.fold(0.0, (total, t) => total + (t.total));
  }

   double get totalMontoArticulosVenta {
    if (articulosVenta == null) {
      return 0.0;
    }
    return articulosVenta!.fold(0.0, (total, av) => total + (av.totalVenta));
  }

   double get totalMontoViaticos {
    if (viaticos == null) {
      return 0.0;
    }
    return viaticos!.fold(0.0, (total, v) => total + (v.monto ?? 0.0));
  }

   double get totalMontoTransferencias {
    if (transferencias == null) {
      return 0.0;
    }
    return transferencias!.fold(0.0, (total, t) => total + (t.aplicado));
  }

   double get totalMontoCierresDatafono {
    if (cierresDatafono == null) {
      return 0.0;
    }
    return cierresDatafono!.fold(0.0, (total, cd) => total + (cd.monto ?? 0.0));
  }

  double get totalMontotarjetas {
    if (tarjetas == null) {
      return 0.0;
    }
    return tarjetas!.fold(0.0, (total, tarjeta) => total + (tarjeta.monto ?? 0.0));
  }

  double get totalMontocashbacks {
    if (cashbacks == null) {
      return 0.0;
    }
    return cashbacks!.fold(0.0, (total, cashback) => total + (cashback.monto ?? 0.0));
  }

   double get totalDepositosCupones {
    if (depositos == null) {
      return 0.0;
    }
    return depositos!
      .where((deposito) => deposito.moneda! == 'CUPONES')
      .fold(0.0, (total, deposito) => total + (deposito.monto ?? 0.0));
  }

   double get totalDepositosDollar {
    if (depositos == null) {
      return 0.0;
    }
    return depositos!
      .where((deposito) => deposito.moneda! == 'DÓLAR')
      .fold(0.0, (total, deposito) => total + (deposito.monto ?? 0.0));
  }

   double get totalDepositosCheque {
    if (depositos == null) {
      return 0.0;
    }
    return depositos!
      .where((deposito) => deposito.moneda! == 'CHEQUE')
      .fold(0.0, (total, deposito) => total + (deposito.monto ?? 0.0));
  }

   double get totalDepositosColon {
    if (depositos == null) {
      return 0.0;
    }
    return depositos!
      .where((deposito) => deposito.moneda! == 'COLON')
      .fold(0.0, (total, deposito) => total + (deposito.monto ?? 0.0));
  }

  double get totalFacturasCredito {
    if (facturas == null) {
      return 0.0;
    }
    return facturas!
      .where((factura) => factura.plazo! > 0)
      .fold(0.0, (total, factura) => total + (factura.totalFactura ?? 0.0));
  }

   double get totalFacturasContado {
    if (facturas == null) {
      return 0.0;
    }
    return facturas!
      .where((factura) => factura.plazo! == 0)
      .fold(0.0, (total, factura) => total + (factura.totalFactura ?? 0.0));
  }



   double get totalMontoCalibraciones {
    if (calibraciones == null) {
      return 0.0;
    }
    return calibraciones!.fold(0.0, (total, calibracion) => total + (calibracion.monto ?? 0.0));
  }

   double get totalCierre {
    return totalMontotarjetas + totalMontoCierresDatafono + totalFacturasCredito + totalDepositosCheque
     + totalDepositosColon + totalDepositosCupones + totalDepositosDollar + totalMontocashbacks + totalMontoTransferencias 
     + totalMontoCalibraciones + totalMontoViaticos + totalSinpes;  // Combina los resultados de los otros dos getters
  }

  double get diferencia {
    return totalCierre - totalTransacciones;
  }

  // Constructor de fábrica para crear una instancia desde un mapa
  factory CierreCajaGeneral.fromJson(Map<String, dynamic> json) {
    return CierreCajaGeneral(
        
          cierre: json['cierre'] != null ? CierreActivo.fromJson(json['cierre']) : null,         
          depositos: json['depositos'] != null ? (json['depositos'] as List).map((i) => Deposito.fromJson(i)).toList() : null,
          facturas: json['facturas'] != null ? (json['facturas'] as List).map((i) => Factura.fromJson(i)).toList() : null,
          calibraciones: json['calibraciones'] != null ? (json['calibraciones'] as List).map((i) => Calibracion.fromJson(i)).toList() : null,
          cashbacks: json['cashbacks'] != null ? (json['cashbacks'] as List).map((i) => Cashback.fromJson(i)).toList() : null,
          tarjetas: json['tarjetas'] != null ? (json['tarjetas'] as List).map((i) => Tarjeta.fromJson(i)).toList() : null,
          cierresDatafono: json['cierresDatafono'] != null ? (json['cierresDatafono'] as List).map((i) => CierreDatafono.fromJson(i)).toList() : null,
          transferencias: json['transferencias'] != null ? (json['transferencias'] as List).map((i) => TransParcial.fromJson(i)).toList() : null,
          viaticos: json['viaticos'] != null ? (json['viaticos'] as List).map((i) => Viatico.fromJson(i)).toList() : null,
          articulosVenta: json['articulosVenta'] != null ? (json['articulosVenta'] as List).map((i) => ArticuloVenta.fromJson(i)).toList() : null,
          transacciones: json['transacciones'] != null ? (json['transacciones'] as List).map((i) => Transaccion.fromJson(i)).toList() : null,
          inventariofinal: json['inventariofinal'] != null ? (json['inventariofinal'] as List).map((i) => LineaInventario.fromJson(i)).toList() : null,
          peddlers: json['peddlers'] != null ? (json['peddlers'] as List).map((i) => Peddler.fromJson(i)).toList() : null,
          sinpes: json['sinpes'] != null ? (json['sinpes'] as List).map((i) => Sinpe.fromJson(i)).toList() : null,
          //complete this

    );
  }

  // Método para convertir la instancia en un mapa
  Map<String, dynamic> toJson() {
    return {
     
      'Cierre': cierre?.toJson(),      
      'Depositos': depositos?.map((i) => i.toJson()).toList(),
      'Facturas': facturas?.map((i) => i.toJson()).toList(),
      'Calibraciones': calibraciones?.map((i) => i.toJson()).toList(),
      'Cashbacks': cashbacks?.map((i) => i.toJson()).toList(),
      'Tarjetas': tarjetas?.map((i) => i.toJson()).toList(),
      'CierresDatafono': cierresDatafono?.map((i) => i.toJson()).toList(),
      'Transferencias': transferencias?.map((i) => i.toJson()).toList(),
      'Viaticos': viaticos?.map((i) => i.toJson()).toList(),
      'ArticulosVenta': articulosVenta?.map((i) => i.toJson()).toList(),
      'transacciones': transacciones?.map((i) => i.toJson()).toList(),
      'inventariofinal': inventariofinal?.map((i) => i.toJson()).toList(),
      'peddlers': peddlers?.map((i) => i.toJson()).toList(),
      'sinpes': sinpes?.map((i) => i.toJson()).toList(),

    };
  }
}
