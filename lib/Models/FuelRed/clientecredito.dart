class ClienteCredito {
  List<String>? placas;
  String? nombre;
  String? codigo;
  String? email;
  String? documento;
  String? codigoTipoID;
  String? tipo;
  double? saldoPendiente;
  List<String>? emails = [];

  ClienteCredito(
      {this.placas,
      this.nombre,
      this.codigo,
      this.email,
      this.documento,
      this.codigoTipoID,
      this.tipo,
      this.saldoPendiente,  
      this.emails,    
      });

  String obtenerPrimerNombre() {
    List<String> partesNombre = nombre!.split(' ');
    return partesNombre.isNotEmpty ? partesNombre.first : '';
  }

  ClienteCredito.fromJson(Map<String, dynamic> json) {
    if (json['placas'] != null) {
     placas = json['placas'].cast<String>();
    } else{
      placas=[];
    }
   
    
    nombre = json['nombre'];
    codigo = json['codigo'];
    email = json['email'];
    emails!.add(email??'');
    documento = json['documento'];
    codigoTipoID = json['codigoTipoID'];
    tipo = json['tipo'];
    saldoPendiente = (json['saldoPendiente'] as num?)?.toDouble() ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['placas'] = placas;
    data['nombre'] = nombre;
    data['codigo'] = codigo;
    data['email'] = email;
    data['documento'] = documento;
    data['tipo'] = tipo;
    return data;
  }
}