class Constans {
  static String get remoteAPI => 'https://estacionsangerardo.com';
  static String get apiUrl => 'https://api.estacionsangerardo.com';
  static String get localAPI => 'http://10.0.2.2';
  static String get apiHacienda => 'https://api.hacienda.go.cr/fe/ae';
  // IP del PC donde corre la API nueva (misma LAN que el dispositivo de prueba).
  static String get localDesarrollo => 'http://192.168.1.39:8088';

  /// Toggle: apuntar al API nuevo (true) vs API vieja en prod (false).
  /// Mientras dura la migración, dejarlo en true.
  static const bool useNewApi = true;

  static String getAPIUrl() {
    return useNewApi ? localDesarrollo : apiUrl;
  }

  static String imagenesUrlRemoto = 'https://estacionsangerardo.com/photos';
  static String imagenesUrlLocal = 'https://api.estacionsangerardo.com/photos';
  static String imagenesUrl = 'http://10.0.2.2:80/photos';

  static String getImagenesUrl() {
    return imagenesUrlLocal;
  }

  static String baseUrlConsole = 'https://console.estacionsangerardo.com/api/';
  static String monitoringHubUrl = 'https://console.estacionsangerardo.com/hubs/monitoring';

  // ── FuelRed P4S ──────────────────────────────────────────────
  static String fuelRedApiUrl =
      'https://flotilla-fuelred-p4s-production.up.railway.app/api/v1/station-api';
  static String fuelRedWsUrl =
      'wss://flotilla-fuelred-p4s-production.up.railway.app/api/v1/ws/station';
  static String fuelRedApiKey =
      '3f1c9c91841e3d5172c2ea3a4b9b084a5e70514d85897b6ea96b8f7f529a8ca7';
}
