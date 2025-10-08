

class Constans {
    static String get remoteAPI => 'http://200.91.130.215:80'; 
    static String get apiUrl => 'http://192.168.1.3:80'; 
    static String get localAPI => 'http://192.168.1.165:8081'; 
    static String get apiHacienda => 'https://api.hacienda.go.cr/fe/ae'; 
    static String get localDesarrollo => 'http://192.168.1.13:8088';
    static String  getAPIUrl () {
      return  apiUrl;
    }

    static String imagenesUrlRemoto = 'http://200.91.130.215:80/photos'; 
    static String imagenesUrlLocal = 'http://192.168.1.3:80/photos';   
     static String imagenesUrl = 'http://192.168.1.3:80/photos'; 

    static String  getImagenesUrl () {
      return imagenesUrlLocal; 
    }

    static String baseUrlCoreWeb = 'http://192.168.1.39:9012/api/'; 
    static String baseUrlHorustec = 'http://192.168.1.39:9010/api/';
   
}