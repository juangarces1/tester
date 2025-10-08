import 'package:tester/Models/cierrefinal.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/empleado.dart';
import 'package:tester/Models/paid.dart';
import 'package:tester/Models/peddler.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/Models/transferencia.dart';

class Invoice {
  Cliente? cliente;
  Paid? formPago;
  List<Product>? detail;
  bool? isCredit;
  bool? isPeddler;  
  bool? isContado;
  bool? isTicket;
  bool? isProcess;
  bool? isPromo;
  String? placa;
  int? kms;  
  String? observaciones;
  Empleado? empleado;
  CierreFinal? cierre;
  Peddler? peddler;
 


  Invoice(
      {this.cliente,
      this.formPago,
      this.detail,
      this.isCredit,
      this.isPeddler,
      this.isTicket,
      this.isProcess,
      this.observaciones,
      this.empleado,
      this.cierre,    
      this.isContado,     
      this.kms,
      this.placa,
      this.peddler,
      this.isPromo,
     
   });

   String get tipoInvoice {
    if (isCredit == true) {
      return 'Credito';
    } else if (isPeddler == true) {
      return 'Peddler';
    } else if (isContado == true) {
      return 'Contado';
    } else if (isTicket == true) {
      return 'Ticket';
    } else if (isProcess == true) {
      return 'Procesar';
    }
    return ''; // Retorna un string vacío si todos son false
  }


   double get total {
    if (detail == null || detail!.isEmpty) return 0;

    double totalSuma = 0;
    for (var producto in detail!) {
      if (producto.transaccion != 0) {
        totalSuma += producto.total;  // Sumar el campo 'total' si la unidad es 'L'
      } else {
        totalSuma += producto.totalProducto;  // Sumar el campo 'totalProducto' si la unidad no es 'L'
      }
    }
    return totalSuma;
  }

   int get numeroProductos {
   return detail == null || detail!.isEmpty ? 0 :   detail!.length;
  }

   void resetFactura() {
      detail!.clear();
      formPago!.totalBac = 0;
      formPago!.totalBn = 0;
      formPago!.totalCheques=0;
      formPago!.totalCupones=0;
      formPago!.totalDav=0;
      formPago!.totalDollars=0;
      formPago!.totalEfectivo=0;
      formPago!.totalPuntos=0;
      formPago!.totalSctia=0;
      formPago!.transfer.totalTransfer=0;
      formPago!.totalSinpe=0;
      // ... Resto de los campos a resetear
      formPago!.transfer =  Transferencia(
        cliente: Cliente(
          nombre: '', 
          documento: '', 
          codigoTipoID: '', 
          email: '', 
          puntos: 0, 
          codigo: '', 
          telefono: ''
        ), 
        transfers: [], 
        monto: 0, 
        totalTransfer: 0
      );
        formPago!.clienteFactura=Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos: 0, codigo: '', telefono: '');
         formPago!.clientePuntos=Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos: 0, codigo: '', telefono: '');
      formPago!.sinpe = Sinpe(numFact: '', fecha: DateTime.now(), id: 0, idCierre: 0, activo: 0, monto: 0, nombreEmpleado: '', nota: '', numComprobante: '');
          
      // ... Continuar con el reseteo de los campos necesarios
     
  }

  // You might also want to add a toJson method, just in case!
   double get saldo {    
    return
         total
         -formPago!.totalEfectivo
         -formPago!.totalBac
         -formPago!.totalDav
         -formPago!.totalBn
         -formPago!.totalSctia
         -formPago!.totalDollars
         -formPago!.totalCheques
         -formPago!.totalCupones
         -formPago!.totalPuntos
         -formPago!.totalTransfer
         -formPago!.totalSinpe;
   } 



  List<Product> buscarAcumulacion (){
       List<Product> acumulacion = [];
      for (var prodCarro in detail!) {
        if (prodCarro.transaccion != 0 && prodCarro.cantidad > 90 ) {     
          acumulacion.add(prodCarro);
        }
      }
      return acumulacion;
  }
 
}