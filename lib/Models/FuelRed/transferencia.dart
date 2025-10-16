import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Models/FuelRed/transparcial.dart';

class Transferencia {  
    Cliente cliente = Cliente(
      nombre: "",
      documento: "",
      codigoTipoID: "",
      email: "",
      puntos: 0,
      codigo: '',
      telefono: '',
    ); 
    List<TransParcial> transfers = [];
    double monto = 0; 
    double totalTransfer = 0; 



  Transferencia({
      required this.cliente,      
      required this.transfers,
      required this.monto,
      required this.totalTransfer,
  }); 

   double get saldoActual {
    double sumaAplicado = transfers.fold(0, (total, tr) => total + tr.aplicado);
    return totalTransfer - sumaAplicado;
  }

    double get totalAplicado {
    double sumaAplicado = transfers.fold(0, (total, tr) => total + tr.aplicado);
    return  sumaAplicado;
  }
 
  Transferencia.fromJson(Map<String, dynamic> json) {    
    cliente = Cliente.fromJson(json['cliente']);
     if (json['transfers'] != null) {
      transfers = [];
      json['transfers'].forEach((d) {
        transfers.add(TransParcial.fromJson(d));
      });
    }
     monto = json['monto'];
    totalTransfer = json['totalTransfer'];
  }
   
   Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};    
    data['cliente']=cliente.toJson();
    data['transfers'] = transfers.map((d) => d.toJson()).toList();
    data['monto'] = monto;   
    data['totalTransfer'] = totalTransfer;

    return data;
  } 

  

   void setTotalTransfer(double saldo){
  
      totalTransfer=saldo;
  
      for (final tr in transfers){
        totalTransfer -=  tr.aplicado;
      }   
   
  }

}