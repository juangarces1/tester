

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
    id = json['id'];
    saldo = json['saldo'];   
    aplicado = json['aplicado'];
    cuenta = json['cuenta']; 
    numeroDeposito = json['numeroDeposito']; 
     cliente = json['cliente']; 
     banco=json['banco']; 
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