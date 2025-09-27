class ActividadInfo {
  final String? estado;
  final String? tipo;
  final String? codigo;
  final String? descripcion;

  ActividadInfo({
    this.estado,
    this.tipo,
    this.codigo,
    this.descripcion,
  });

  /// Getter equivalente a CodigoDescripcion en C#
  String get codigoDescripcion => "${codigo ?? ''} - ${descripcion ?? ''}".trim();

  /// Factory para crear desde JSON
  factory ActividadInfo.fromJson(Map<String, dynamic> json) {
    return ActividadInfo(
      estado: json['estado'] as String?,
      tipo: json['tipo'] as String?,
      codigo: json['codigo'] as String?,
      descripcion: json['descripcion'] as String?,
    );
  }

  /// Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'estado': estado,
      'tipo': tipo,
      'codigo': codigo,
      'descripcion': descripcion,
    };
  }
}
