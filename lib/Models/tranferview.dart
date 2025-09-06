class Transferview { 
  String cliente = ''; 
  int id = 0;
  String cuenta = '';  
  int saldo = 0;
  String numeroDeposito = ""; 
  int monto = 0;
 
  Transferview({
    required this.cliente,
    required this.id,   
    required this.cuenta,
    required this.saldo,
    required this.numeroDeposito, 
    required this.monto, 

  });

  Transferview.fromJson(Map<String, dynamic> json) {  
    cliente = json['cliente'];
    id = json['id'];   
    cuenta = json['cuenta'];
    saldo = json['saldo'];
    numeroDeposito = json['numeroDeposito']; 
    monto = json['monto']; 
  }

  

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};   
    data['cliente'] = cliente;  
    data['id'] = id;
    data['cuenta'] = cuenta;   
    data['saldo'] = saldo; 
    data['numeroDeposito'] = numeroDeposito;     
    data['monto'] = monto;     
    return data;
  }
}