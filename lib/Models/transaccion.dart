class Transaccion {
  int idtransaccion = 0;
  int numero =0;
  String fechatransaccion = "";
  int dispensador = 0;
  int idproducto = 0;
  String nombreproducto="";
  int total = 0 ;
  double volumen = 0;
  int preciounitario = 0 ;
  int idcierre = 0 ;
  String estado ="";
  String entregatarjeta ="";
  String canjetarjeta ="";
  String pan="";
  String nombrecliente ="";
  String facturada ="";
  String? creacion;
  String? subir;

  Transaccion(
      {required this.idtransaccion,
      required this.numero,
      required this.fechatransaccion,
      required this.dispensador,
      required this.idproducto,
      required this.nombreproducto,
      required this.total,
      required this.volumen,
      required this.preciounitario,
      required this.idcierre,
      required this.estado,
      required this.entregatarjeta,
      required this.canjetarjeta,
      required this.pan,
      required this.nombrecliente,
      required this.facturada,
      this.creacion,
      this.subir});

  Transaccion.fromJson(Map<String, dynamic> json) {
    idtransaccion = json['idtransaccion'];
    numero = json['numero'];
    fechatransaccion =  json['fechatransaccion'];
    dispensador = json['dispensador'];
    idproducto = json['idproducto'];
    nombreproducto = json['nombreproducto'];
    total = json['total'];
    var x = json['volumen'];
    if (x.runtimeType==int)
    {
       volumen = (x).toDouble();
    }
    else{
        volumen = json['volumen'];
    }    
    preciounitario = json['preciounitario'];
    idcierre = json['idcierre'];
    estado = json['estado'];
    entregatarjeta = json['entregatarjeta'];
    canjetarjeta = json['canjetarjeta'];
    pan = json['pan'];
    nombrecliente = json['nombrecliente'];
    facturada = json['facturada'];
    creacion = json['creacion'];
    subir = json['subir'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idtransaccion'] = idtransaccion;
    data['numero'] = numero;
    data['fechatransaccion'] = fechatransaccion;
    data['dispensador'] = dispensador;
    data['idproducto'] = idproducto;
    data['nombreproducto'] = nombreproducto;
    data['total'] = total;
    data['volumen'] = volumen;
    data['preciounitario'] = preciounitario;
    data['idcierre'] = idcierre;
    data['estado'] = estado;
    data['entregatarjeta'] = entregatarjeta;
    data['canjetarjeta'] = canjetarjeta;
    data['pan'] = pan;
    data['nombrecliente'] = nombrecliente;
    data['facturada'] = facturada;
    data['creacion'] = creacion;
    data['subir'] = subir;
    return data;
  }
  bool get isUnpaid =>
      estado.toLowerCase() == 'copiado';
  bool get isFacturada =>
      facturada.trim().toUpperCase() == 'SI';
}