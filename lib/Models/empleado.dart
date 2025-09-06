// ignore: file_names
class Empleado {
  int cedulaEmpleado = 0;
  String nombre = ''; 
  String apellido1 = '';
  String apellido2 = '';  
  String turno = '';
  String tipoempleado ='';
 
  Empleado({
    required this.cedulaEmpleado,
    required this.nombre,   
    required this.apellido1,
    required this.apellido2,
    required this.turno,
    required this.tipoempleado,   
  });

  Empleado.fromJson(Map<String, dynamic> json) {  
    cedulaEmpleado = json['cedulaempleado'];
    nombre = json['nombre'];   
    apellido1 = json['apellido1'];
    apellido2 = json['apellido2'];   
    turno = json['turno'];
    tipoempleado = json['tipoempleado'];   
    
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cedulaEmpleado'] = cedulaEmpleado;
    data['nombre'] = nombre;  
    data['apellido1'] = apellido1;
    data['apellido2'] = apellido2;   
    data['turno'] = turno;
    data['tipoempleado'] = tipoempleado;   
    return data;
  }

   String get nombreCompleto {
    return '$nombre $apellido1';
  }
}