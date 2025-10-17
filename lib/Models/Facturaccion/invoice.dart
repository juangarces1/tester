
import 'package:tester/Models/FuelRed/cierrefinal.dart';
import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Models/FuelRed/empleado.dart';
import 'package:tester/Models/FuelRed/paid.dart';
import 'package:tester/Models/FuelRed/peddler.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/Models/FuelRed/transferencia.dart';


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

   double get totalLitros {
    if (detail == null || detail!.isEmpty) return 0;

    double litros = 0;
    for (var producto in detail!) {
      if (producto.transaccion != 0) {
        litros += producto.cantidad;
      }
    }
    return litros;
  }

   int get numeroProductos {
   return detail == null || detail!.isEmpty ? 0 :   detail!.length;
  }

  static Invoice createInitializedInvoice(CierreFinal? cierre, Empleado? usuario) {

    // Cliente por defecto
    final defaultCliente = Cliente(
        nombre: '',
        documento: '',
        codigoTipoID: '',
        email: '',
        puntos: 0,
        codigo: '',
        telefono: '');

    // Transferencia por defecto
    final defaultTransferencia = Transferencia(
        cliente: defaultCliente, transfers: [], monto: 0, totalTransfer: 0);

    // Sinpe por defecto
    final defaultSinpe = Sinpe(
        id: 0,
        numComprobante: '',
        nota: '',
        idCierre: 0,
        nombreEmpleado: '',
        fecha: DateTime.now(),
        numFact: '',
        activo: 0, // Usar 0 o 1 según el valor inicial esperado
        monto: 0);

    // Paid (forma de pago) por defecto
    final defaultFormPago = Paid(
      totalEfectivo: 0,
      totalBac: 0,
      totalDav: 0,
      totalBn: 0,
      totalSctia: 0,
      totalDollars: 0,
      totalCheques: 0,
      totalCupones: 0,
      totalPuntos: 0,
      totalTransfer: 0,
      clienteFactura: defaultCliente,
      transfer: defaultTransferencia,
      showTotal: false,
      showFact: false,
      totalSinpe: 0,
      sinpe: defaultSinpe,
      clientePuntos: defaultCliente,
    );

    // Peddler por defecto
    final defaultPeddler = Peddler(
        placa: '', km: '', chofer: '', observaciones: '', orden: '');

    return Invoice(
      cliente: defaultCliente,
      formPago: defaultFormPago,
      detail: [],
      isCredit: false,
      isPeddler: false,
      isContado: false,
      isTicket: false,
      isProcess: false,
      isPromo: false,
      placa: '',
      kms: 0,
      observaciones: '',
      empleado: usuario, // Se puede pasar o será null
      cierre: cierre, // Se puede pasar o será null
      peddler: defaultPeddler,
    );
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