

class TransParcial { 
  int id = 0; 
  int saldo = 0;
  int aplicado = 0;
  String cuenta = "";
  String numeroDeposito = "";
  String cliente = "";
  String banco ="";
  
 
 
  TransParcial({
    required this.id,
    required this.saldo,   
    required this.aplicado,
    required this.cuenta, 
    required this.numeroDeposito,  
    required this.cliente,  
    required this.banco
    
  });

  TransParcial.fromJson(Map<String, dynamic> json) {
    id = (json['id'] ?? 0) as int;
    saldo = (json['saldo'] ?? 0) as int;
    aplicado = (json['aplicado'] ?? 0) as int;
    cuenta = (json['cuenta'] ?? '') as String;
    numeroDeposito = (json['numeroDeposito'] ?? '') as String;
    cliente = (json['cliente'] ?? '') as String;
    banco = (json['banco'] ?? '') as String;
  }

  

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};   
    data['id'] = id;  
    data['saldo'] = saldo;
    data['aplicado'] = aplicado;   
    data['cuenta'] = cuenta; 
    data['numeroDeposito'] = numeroDeposito;     
     data['cliente'] = cliente;  
      data['banco'] = banco;    
      
    return data;
  }
}