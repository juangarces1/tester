class Constans {
  static String get remoteAPI => 'https://estacionsangerardo.com';
  static String get apiUrl => 'http://192.168.1.3:80';
  static String get localAPI => 'http://192.168.1.3';
  static String get apiHacienda => 'https://api.hacienda.go.cr/fe/ae';
  static String get localDesarrollo => 'http://192.168.1.13:8088';
  static String getAPIUrl() {
    return remoteAPI;
  }

  static String imagenesUrlRemoto = 'https://estacionsangerardo.com/photos';
  static String imagenesUrlLocal = 'http://192.168.1.3:80/photos';
  static String imagenesUrl = 'http://192.168.1.3:80/photos';

  static String getImagenesUrl() {
    return imagenesUrlRemoto;
  }

  // static String baseUrlCoreWeb = 'http://192.168.1.39:9012/api/';
  // static String baseUrlHorustec = 'http://192.168.1.39:9010/api/';

  static String baseUrlCoreWeb =
      'https://costarica-demo-9012.asptienda.com/api/';
  static String baseUrlHorustec =
      'https://costarica-demo-9010.asptienda.com/api/';
}
