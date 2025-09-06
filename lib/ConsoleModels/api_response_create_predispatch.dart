class ApiResponse {
  final bool success;
  final Data data;
  final List<Message> messageList;

  ApiResponse({
    required this.success,
    required this.data,
    required this.messageList,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
        success: json['success'] as bool,
        data: Data.fromJson(json['data'] as Map<String, dynamic>),
        messageList: (json['messageList'] as List<dynamic>)
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data.toJson(),
        'messageList': messageList.map((e) => e.toJson()).toList(),
      };
}

class Data {
  final int type;
  final int dispenserId;
  final int hoseId;
  final num amountRequest;
  final num amountDispense;
  final num volumenDispense;
  final num price;
  final String saleId;
  final int productId;
  final int saleNumber;

  Data({
    required this.type,
    required this.dispenserId,
    required this.hoseId,
    required this.amountRequest,
    required this.amountDispense,
    required this.volumenDispense,
    required this.price,
    required this.saleId,
    required this.productId,
    required this.saleNumber,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        type: json['type'] as int,
        dispenserId: json['dispenserId'] as int,
        hoseId: json['hoseId'] as int,
        amountRequest: json['amountRequest'] as num,
        amountDispense: json['amountDispense'] as num,
        volumenDispense: json['volumenDispense'] as num,
        price: json['price'] as num,
        saleId: json['saleId'] as String,
        productId: json['productId'] as int,
        saleNumber: json['saleNumber'] as int,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'dispenserId': dispenserId,
        'hoseId': hoseId,
        'amountRequest': amountRequest,
        'amountDispense': amountDispense,
        'volumenDispense': volumenDispense,
        'price': price,
        'saleId': saleId,
        'productId': productId,
        'saleNumber': saleNumber,
      };
}

class Message {
  final int code;
  final String description;

  Message({
    required this.code,
    required this.description,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        code: json['code'] as int,
        description: json['description'] as String,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
      };
}
