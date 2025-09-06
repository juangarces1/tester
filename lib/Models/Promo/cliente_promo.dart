class ClientePromo {
  int id;
  String email;
  String firstName;
  String lastName;
  String document;

  ClientePromo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.document,
  });

 
  // Método fromJson
  factory ClientePromo.fromJson(Map<String, dynamic> json) {
    return ClientePromo(
      id: json['id'] ?? 0,  // Valor por defecto
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      document: json['document'] ?? '',     
    );
  }

  // Método toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'document': document,      
    };
  }

  String get  fullName => '$firstName $lastName';
}
