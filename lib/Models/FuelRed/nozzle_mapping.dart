class NozzleMapping {
  final int id;
  final String hoseKey;
  final int dispenserNumber;
  final int hoseNumber;
  final String grade;

  const NozzleMapping({
    required this.id,
    required this.hoseKey,
    required this.dispenserNumber,
    required this.hoseNumber,
    required this.grade,
  });

  factory NozzleMapping.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, int defaultValue) {
      if (v == null) return defaultValue;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.toString()) ?? defaultValue;
      return defaultValue;
    }

    return NozzleMapping(
      id: toInt(json['id'] ?? json['Id'], 0),
      hoseKey: (json['hoseKey'] ?? json['HoseKey'] ?? '').toString(),
      dispenserNumber: toInt(
          json['dispenserNumber'] ??
              json['DispenserNumber'] ??
              json['dispensador'] ??
              json['Dispensador'],
          0),
      hoseNumber: toInt(
          json['hoseNumber'] ??
              json['HoseNumber'] ??
              json['nozzleNumber'] ??
              json['NozzleNumber'],
          0),
      grade: (json['grade'] ?? json['Grade'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hoseKey': hoseKey,
        'dispenserNumber': dispenserNumber,
        'hoseNumber': hoseNumber,
        'grade': grade,
      };
}
