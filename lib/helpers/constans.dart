class Constans {
  static String get remoteAPI => 'https://estacionsangerardo.com';
  static String get apiUrl => 'http://192.168.1.3:80';
  static String get localAPI => 'http://10.0.2.2';
  static String get apiHacienda => 'https://api.hacienda.go.cr/fe/ae';
  static String get localDesarrollo => 'http://192.168.1.13:8088';
  static String getAPIUrl() {
    return apiUrl;
  }

  static String imagenesUrlRemoto = 'https://estacionsangerardo.com/photos';
  static String imagenesUrlLocal = 'http://192.168.1.3:80/photos';
  static String imagenesUrl = 'http://10.0.2.2:80/photos';

  static String getImagenesUrl() {
    return imagenesUrl;
  }

  // static String baseUrlConsole = ' http://192.168.1.46:5000/api/';
  // static String monitoringHubUrl = ' http://192.168.1.46:5000/hubs/monitoring';

  static String baseUrlConsole = 'http://10.0.2.2:5000/api/';
  static String monitoringHubUrl = 'http://10.0.2.2:5000/hubs/monitoring';
}
