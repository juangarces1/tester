class Money {
  int? idmoneda; 
  String? nombre;  

  Money(
      {this.idmoneda,
      this.nombre,
      });

  Money.fromJson(Map<String, dynamic> json) {
    idmoneda = json['idmoneda'];
    nombre = json['nombre'];   
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idmoneda'] = idmoneda;
    data['nombre'] = nombre;    
    return data;
  }
}