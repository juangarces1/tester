class InventoryItem {
  String article;
  String code;
  int quantity;
  int adjustment;
  int? show;

   

  InventoryItem({required this.article, required this.code, required this.quantity, required this.adjustment, this.show});

   int get difference => adjustment - quantity;

    // Método para crear una nueva instancia de InventoryItem a partir de un mapa.
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      article: json['article'] as String,
      code: json['code'] as String,
      quantity: json['quantity'] as int,
      adjustment: json['adjustment'] as int,
      show : json['quantity'] as int,
    );
  }

  // Método para convertir la instancia de InventoryItem en un mapa.
  Map<String, dynamic> toJson() {
    return {
      'article': article,
      'code': code,
      'quantity': quantity,
      'adjustment': adjustment,
    };
  }
}