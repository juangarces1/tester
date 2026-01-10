class NozzleMapping {
  final int id;
  final String hoseKey;
  final int dispenserNumber;
  final int hoseNumber;

  const NozzleMapping({
    required this.id,
    required this.hoseKey,
    required this.dispenserNumber,
    required this.hoseNumber,
  });

  factory NozzleMapping.fromJson(Map<String, dynamic> json) {
    return NozzleMapping(
      id: json['id'] as int,
      hoseKey: json['hoseKey'] as String,
      dispenserNumber: json['dispenserNumber'] as int,
      hoseNumber: json['hoseNumber'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hoseKey': hoseKey,
    'dispenserNumber': dispenserNumber,
    'hoseNumber': hoseNumber,
  };
}
