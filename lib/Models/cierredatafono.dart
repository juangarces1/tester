class CierreDatafono {
  int? idcierredatafono;
  int? idbanco;
  double? monto;
  int? cedulaempleado;
  String? fechacierre;
  String? terminal;
  int? idcierre;
  int? idregistrodatafono;  
  String? banco;

  CierreDatafono(
      {this.idcierredatafono,
      this.idbanco,
      this.monto,
      this.cedulaempleado,
      this.fechacierre,
      this.terminal,
      this.idcierre,
      this.idregistrodatafono,      
      this.banco});

  CierreDatafono.fromJson(Map<String, dynamic> json) {
    idcierredatafono = json['idcierredatafono'];
    idbanco = json['idbanco'];
    var x = json['monto'];
    x.runtimeType==int ? monto = (x).toDouble() : monto = json['monto'];    
    cedulaempleado = json['cedulaempleado'];
    fechacierre = json['fechacierre'];
    terminal = json['terminal'];
    idcierre = json['idcierre'];
    idregistrodatafono = json['idregistrodatafono'];    
     banco = json['banco'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idcierredatafono'] = idcierredatafono;
    data['idbanco'] = idbanco;
    data['monto'] = monto;
    data['cedulaempleado'] = cedulaempleado;
    data['fechacierre'] = fechacierre;
    data['terminal'] = terminal;
    data['idcierre'] = idcierre;
    data['idregistrodatafono'] = idregistrodatafono;    
    data['comision']=0;
    return data;
  }
}