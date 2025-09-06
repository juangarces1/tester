// ==================== MODELO ====================
import 'dart:convert';

import 'package:http/http.dart' as http;

class DispatchResponse {
  final int id;
  final int nozzleNumber;
  final DateTime dateTime;
  final double price;       // precio por litro
  final double volume;      // litros
  final double total;       // importe

  DispatchResponse({
    required this.id,
    required this.nozzleNumber,
    required this.dateTime,
    required this.price,
    required this.volume,
    required this.total,
  });

  factory DispatchResponse.fromJson(Map<String, dynamic> j) => DispatchResponse(
        id: j['id'],
        nozzleNumber: j['nozzleNumber'],
        dateTime: DateTime.parse(j['dateTime']),
        price: (j['unitPrice'] as num).toDouble(),
        volume: (j['totalVolume'] as num).toDouble(),
        total: (j['totalValue'] as num).toDouble(),
      );
}

// ==================== HELPER ====================
Future<List<DispatchResponse>> fetchLastDispatches(int nozzle) async {
  final url = Uri.parse(
    'https://gasolineria-aspdemo012.asptienda.com/'
    'api/horustech/dispatches?NozzleNumber=$nozzle&PageIndex=1&PageSize=10',
  );

  final res = await http.get(url, headers: {'accept': 'application/json'});

  if (res.statusCode == 200) {
    final root = jsonDecode(res.body) as Map<String, dynamic>;
    final listJson = root['data'] as List;
    return listJson
        .map((e) => DispatchResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Error ${res.statusCode}: ${res.reasonPhrase}');
}

class PagedDispatches {
  final List<DispatchResponse> data;
  final int pageIndex;
  final int pageCount;
  final int pageSize;
  final int totalCount;

  PagedDispatches({
    required this.data,
    required this.pageIndex,
    required this.pageCount,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagedDispatches.fromJson(Map<String, dynamic> j) => PagedDispatches(
        data: (j['data'] as List)
            .map((e) => DispatchResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        pageIndex: j['pageIndex'] as int,
        pageCount: j['pageCount'] as int,
        pageSize: j['pageSize'] as int,
        totalCount: j['totalCount'] as int,
      );
}

Future<PagedDispatches> fetchDispatchPage({
  required int nozzle,
  required int pageIndex,        // 1-based
  int pageSize = 5,
}) async {
  final url = Uri.parse(
    'https://gasolineria-aspdemo012.asptienda.com/'
    'api/horustech/dispatches'
    '?NozzleNumber=$nozzle'
    '&PageIndex=$pageIndex'
    '&PageSize=$pageSize',
  );

  final res = await http.get(url, headers: {'accept': 'application/json'});

  if (res.statusCode == 200) {
    return PagedDispatches.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }
  throw Exception('Error ${res.statusCode}: ${res.reasonPhrase}');
}