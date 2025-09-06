// ignore: file_names
class Cliente { 
  String nombre = ''; 
  String documento = '';
  String codigoTipoID = '';  
  String email = '';
  int puntos=0; 
  String codigo='';
  String? tipo;
  String telefono = '';
  List<String>? placas = [];
  List<String>? emails = [];
 
  Cliente({
    required this.nombre,
    required this.documento,   
    required this.codigoTipoID,
    required this.email,
    required this.puntos,  
    required this.codigo,
    this.tipo,  
    required this.telefono,
    this.placas,
    this.emails,

  });

   String obtenerPrimerNombre() {
    List<String> partesNombre = nombre.split(' ');
    return partesNombre.isNotEmpty ? partesNombre.first : '';
  }

  Cliente.fromJson(Map<String, dynamic> json) {  
    nombre = json['nombre'];
    documento = json['documento'];   
    codigoTipoID = json['codigoTipoID'];
    email = json['email'];
    puntos = json['puntos'];
     emails!.add(email);
    if (json['codigo'] != null) {
       codigo = json['codigo']; 
    }
     
    if (json['telefono'] != null) {
      telefono = json['telefono'];
    }
    else {
      telefono = '';
    }
    tipo = json['tipo'];
    
  }

   Cliente.fromHaciendaJson(Map<String, dynamic> json) {  
    nombre = json['nombre'];      
    codigoTipoID = json['tipoIdentificacion'];    
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};   
    data['nombre'] = nombre;  
    data['documento'] = documento;
    data['codigoTipoID'] = codigoTipoID;   
    data['email'] = email; 
    data['puntos'] = puntos;    
    data['codigo'] = codigo;    
    data['tipo']=tipo; 
    data['telefono']=telefono;
    return data;
  }
}