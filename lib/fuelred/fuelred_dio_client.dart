import 'package:dio/dio.dart';
import 'package:tester/helpers/constans.dart';

/// Cliente Dio exclusivo para FuelRed P4S.
/// Autenticación por X-Api-Key (no JWT).
class FuelRedDioClient {
  FuelRedDioClient._();

  static final Dio instance = Dio(BaseOptions(
    baseUrl: Constans.fuelRedApiUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Api-Key': Constans.fuelRedApiKey,
    },
    validateStatus: (s) => s != null && s < 500,
  ));

  /// Actualiza el API key en runtime (ej. desde config o login).
  static void setApiKey(String key) {
    Constans.fuelRedApiKey = key;
    instance.options.headers['X-Api-Key'] = key;
  }
}
