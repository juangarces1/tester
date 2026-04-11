class Constans {
  static String get remoteAPI => 'https://estacionsangerardo.com';
  static String get apiUrl => 'https://api.estacionsangerardo.com';
  static String get localAPI => 'http://10.0.2.2';
  static String get apiHacienda => 'https://api.hacienda.go.cr/fe/ae';
  static String get localDesarrollo => 'http://192.168.1.13:8088';
  static String getAPIUrl() {
    return apiUrl;
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
