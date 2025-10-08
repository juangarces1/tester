import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tester/Models/LogIn/inventory_item.dart';
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/ResumenCierre/cierre_caja_general.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/bank.dart';
import 'package:tester/Models/cashback.dart';
import 'package:tester/Models/cierreactivo.dart';
import 'package:tester/Models/cierredatafono.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/clientecredito.dart';
import 'package:tester/Models/datafono.dart';
import 'package:tester/Models/deposito.dart';
import 'package:tester/Models/factura.dart';
import 'package:tester/Models/money.dart';
import 'package:tester/Models/peddler.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/Models/tranferview.dart';
import 'package:tester/Models/transaccion.dart';
import 'package:tester/Models/transparcial.dart';
import 'package:tester/Models/viatico.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/helpers/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';



class ApiHelper {

  static Future<Response> getCierre(String cierre) async {  

    var url = Uri.parse('${Constans.getAPIUrl()}/api/Caja/$cierre');
    // try {
        var response = await http.get(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        );
      
        // Check for 200 OK response
        if (response.statusCode == 200) {

          var decodedJson = jsonDecode(response.body);
          return Response(isSuccess: true, result: CierreCajaGeneral.fromJson(decodedJson));
        } else if (response.statusCode == 204) {
          // No content
          return Response(isSuccess: true, message: '', result: []);
        } else {
          // Handle other statuses, maybe something went wrong
          return Response(isSuccess: false, message: "Error: ${response.body}");
        }
   
 } 

  static Future<Response> getCierreActivo(String cierre) async {  

    var url = Uri.parse('${Constans.getAPIUrl()}/api/Caja/GetCierreActivo/$cierre');
    // try {
        var response = await http.get(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        );
      
        // Check for 200 OK response
        if (response.statusCode == 200) {

          var decodedJson = jsonDecode(response.body);
          return Response(isSuccess: true, result: CierreCajaGeneral.fromJson(decodedJson));
        } else if (response.statusCode == 204) {
          // No content
          return Response(isSuccess: true, message: '', result: []);
        } else {
          // Handle other statuses, maybe something went wrong
          return Response(isSuccess: false, message: "Error: ${response.body}");
        }
   
 } 

 static Future<Response> preCierre(String cierre) async {  

    var url = Uri.parse('${Constans.getAPIUrl()}/api/Facturacion/SranbyCierre/$cierre');
    // try {
        var response = await http.get(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        );
      
        // Check for 200 OK response
        if (response.statusCode == 200) {

        
          return Response(isSuccess: true, result: response.body);
        } else if (response.statusCode == 204) {
          // No content
          return Response(isSuccess: true, message: '', result: []);
        } else {
          // Handle other statuses, maybe something went wrong
          return Response(isSuccess: false, message: "Error: ${response.body}");
        }
   
 } 

  static Future<Response> setCierre(String cierre) async {  

    var url = Uri.parse('${Constans.getAPIUrl()}/api/Facturacion/CrearCierre/$cierre');
    // try {
        var response = await http.get(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        );
      
        // Check for 200 OK response
        if (response.statusCode == 200) {

        
          return Response(isSuccess: true, result: response.body);
        } else if (response.statusCode == 204) {
          // No content
          return Response(isSuccess: true, message: '', result: []);
        } else {
          // Handle other statuses, maybe something went wrong
          return Response(isSuccess: false, message: "Error: ${response.body}");
        }
   
 } 

static Future<Response> getLogIn(int? zona, int? cedula) async {  

    var url = Uri.parse('${Constans.getAPIUrl()}/api/users/GetLogInOpen/$zona-$cedula');
     try {
        var response = await http.get(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        );
      
        // Check for 200 OK response
        if (response.statusCode == 200) {

          var decodedJson = jsonDecode(response.body);
          return Response(isSuccess: true, result: AllFact.fromJson(decodedJson));
        } else if (response.statusCode == 204) {
          // No content
          return Response(isSuccess: true, message: '', result: []);
        } else {
          // Handle other statuses, maybe something went wrong
          return Response(isSuccess: false, message: "Error: ${response.body}");
        }
      } catch (e) {
        // Catch any other errors, like JSON parsing errors
       
        return Response(isSuccess: false, message: "Exception: ${e.toString()}");
      }
 }

 static Future<Response> getLogInNuevo(int? zona, int? cedula) async {  

    var url = Uri.parse('${Constans.getAPIUrl()}/api/users/GetLogInNuevo/$zona-$cedula');
     try {
        var response = await http.get(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        );
      
        // Check for 200 OK response
        if (response.statusCode == 200) {

          var decodedJson = jsonDecode(response.body);
          return Response(isSuccess: true, result: AllFact.fromJson(decodedJson));
        } else if (response.statusCode == 204) {
          // No content
          return Response(isSuccess: true, message: '', result: []);
        } else {
          // Handle other statuses, maybe something went wrong
          return Response(isSuccess: false, message: "Error: ${response.body}");
        }
      } catch (e) {
        // Catch any other errors, like JSON parsing errors
       
        return Response(isSuccess: false, message: "Exception: ${e.toString()}");
      }
 }

  static Future<Response> getInventarioInicial(int? zona) async {  

    var url = Uri.parse('${Constans.getAPIUrl()}/api/users/GetInventInicial/$zona');
     try {
        var response = await http.get(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        );
      
        // Check for 200 OK response
           var body = response.body;
            if (response.statusCode >= 400) {
              return Response(isSuccess: false, message: body);
            }
            List<InventoryItem> inventario =[];
            var decodedJson = jsonDecode(body);
            if(decodedJson != null){      

              for (var item in decodedJson){
                inventario.add(InventoryItem.fromJson(item));
              }
            
            }
            return Response(isSuccess: true, result: inventario);   

      } catch (e) {
        // Catch any other errors, like JSON parsing errors
       
        return Response(isSuccess: false, message: "Exception: ${e.toString()}");
      }
 }

static Future<Response> getClienteCredito() async {      
   var url = Uri.parse('${Constans.getAPIUrl()}/api/Clientes/GetClientsYam');
   
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
     var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Cliente> clientes =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        clientes.add(Cliente.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: clientes);      
 }

 static Future<Response> getFactura(String id) async {      
   var url = Uri.parse('${Constans.getAPIUrl()}/api/Facturacion/GetFacturaByNum/$id');
   
     try {
    var response = await http.get(
      url,
      headers: {
        'content-type': 'application/json',
        'accept': 'application/json',
      },
    );

    // Check for 200 OK response
    if (response.statusCode == 200) {
      var decodedJson = jsonDecode(response.body);
     
      return Response(isSuccess: true, message: 'Ok', result: Factura.fromJson(decodedJson));
    } else if (response.statusCode == 404) {
      
      // No content
      return Response(isSuccess: true, message: '', result: []);
    } else {
     
      // Handle other statuses, maybe something went wrong
      return Response(isSuccess: false, message: "Error: ${response.statusCode}");
    }
  } catch (e) {
   
    // Catch any other errors, like JSON parsing errors
    return Response(isSuccess: false, message: "Exception: ${e.toString()}");
  }  
 }

 static Future<Response> getClientesCredito() async {      
   var url = Uri.parse('${Constans.getAPIUrl()}/api/Clientes/GetClientsYam');
   
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Cliente> clientes =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){      

       for (var item in decodedJson){
        clientes.add(Cliente.fromJson(item));
      }
     
     }
     return Response(isSuccess: true, result: clientes);    
 }
 
 static Future<Response> getCierresByDia(DateTime dia) async {      
   var url = Uri.parse('${Constans.getAPIUrl()}/api/Caja/GetCierreByDia/${VariosHelpers.formatYYYYmmDD(dia)}');
   
     
      try {
        var response = await http.get(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
        );
      
        // Check for 200 OK response
        if (response.statusCode == 200) {
         var body = response.body;
         List<CierreActivo> cierres =[];
          var decodedJson = jsonDecode(body);
          if(decodedJson != null){      

            for (var item in decodedJson){
              cierres.add(CierreActivo.fromJson(item));
            }
          
     }
     return Response(isSuccess: true, result: cierres); 
        } else if (response.statusCode == 204) {
          // No content
          return Response(isSuccess: true, message: '', result: []);
        } else {
          // Handle other statuses, maybe something went wrong
          return Response(isSuccess: false, message: "Error: ${response.body}");
        }
       } catch (e) {
         // Catch any other errors, like JSON parsing errors
               return Response(isSuccess: false, message: "Exception: ${e.toString()}");
       }   
 }

static Future<Response> getTransacciones(int? zona) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/TransaccionesApi/GetTransaccionesByZona/$zona');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Transaccion> transacciones =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        transacciones.add(Transaccion.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: transacciones);    
 }

 static Future<Response> getFacturasByCierre(int? cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Facturacion/GetFacturasByCierre/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Factura> facturas =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        facturas.add(Factura.fromJson(item));
      }
     }

    // for (var fact in facturas) {
    //    for (var element in fact.detalles) {
    //       element.images.add(element.imageUrl);
    //    }
    // }
  

     return Response(isSuccess: true, result: facturas);    
 }

  static Future<Response> getEmailsBy(String codigo) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Users/GetEmailsByCodigo/$codigo');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<String> emails =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        emails.add(item);
      }
     }

   
  

     return Response(isSuccess: true, result: emails);    
 }

 static Future<Response> getFacturasByCliente(String id) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Facturacion/GetFacturasByCliente/$id');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Factura> facturas =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        facturas.add(Factura.fromJson(item));
      }
     }

    for (var fact in facturas) {
       for (var element in fact.detalles) {
          element.images.add(element.imageUrl);
       }
    }
  

     return Response(isSuccess: true, result: facturas);    
 }

  static Future<Response> getFacturasCredito(int? cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Facturacion/GetFacturasCreditByCierre/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Factura> facturas =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        facturas.add(Factura.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: facturas);    
 }

 static Future<Response> getTransaccionesByCierre(int? cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/TransaccionesApi/GetTransaccionesByCierre/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Transaccion> transacciones =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        transacciones.add(Transaccion.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: transacciones);    
 }

static Future<Response> getPeddlersByCierre(int? cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Peddler/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Peddler> peddlers =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        peddlers.add(Peddler.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: peddlers);    
 }

static Future<Response> getCierresDatafonos(int cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/CierreDatafonos/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<CierreDatafono> cierres =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        cierres.add(CierreDatafono.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: cierres);    
 }

 static Future<Response> getViaticosByCierre(int cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Viaticos/GetViaticoByCierre/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Viatico> viaticos =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        viaticos.add(Viatico.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: viaticos);    
 }

static Future<Response> getCashBacks(int cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Cashbacks/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Cashback> cashbacks =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        cashbacks.add(Cashback.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: cashbacks);    
 }

 static Future<Response> getSinpes(int cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Sinpes/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Sinpe> sinpes =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        sinpes.add(Sinpe.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: sinpes);    
 }

static Future<Response> getDepositos(int cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Depositos/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Deposito> depositos =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        depositos.add(Deposito.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: depositos);    
 }

static Future<Response> getBanks() async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Cashbacks/GetBanks');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Bank> banks =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        banks.add(Bank.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: banks);    
 }

 static Future<Response> getDatafonos() async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/CierreDatafonos/GetDatafonos');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Datafono> datafonos =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        datafonos.add(Datafono.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: datafonos);    
 }

 static Future<Response> getMoneys() async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Depositos/GetMoneys');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Money> moneys =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        moneys.add(Money.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: moneys);    
 }

 static Future<Response> getTransfes() async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Transferencias/GetTransfers');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Transferview> transfers =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        transfers.add(Transferview.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: transfers);    
 }

  static Future<Response> getTransfesByCierre(int cierre) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Transferencias/GetTransfersByCierre/$cierre');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<TransParcial> transfers =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        transfers.add(TransParcial.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: transfers);    
 }

  static Future<Response> getTransaccionesAsProduct(int? zona) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/TransaccionesApi/GetTransaccionesByZonaAsProducts/$zona');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Product> transacciones =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        transacciones.add(Product.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: transacciones);    
 }

 static Future<Response> getTransaccionAsProductById(int? id) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/TransaccionesApi/GetTransaccionByIdAsProducts/$id');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
   
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
       Product product = Product.fromJson(decodedJson);
     
     
     return Response(isSuccess: true, result:product);    
     } else {
      return Response(isSuccess: false, message: 'Error al decodificar');
     }
 }

  static Future<Response> getProducts(int? zona) async {
    var url = Uri.parse('${Constans.getAPIUrl()}/api/TransaccionesApi/GetProducts/$zona');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Product> products =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        products.add(Product.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: products);    
 }

  static Future<Response> getClienteContado() async {
   var url = Uri.parse('${Constans.getAPIUrl()}/api/Clientes/GetClientsContado');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Cliente> clientes =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        clientes.add(Cliente.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: clientes);    
 }

   static Future<Response> getClientesTransfer() async {
   var url = Uri.parse('${Constans.getAPIUrl()}/api/Otros/GetClientesSanGerardo');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<Cliente> clientes =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        clientes.add(Cliente.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: clientes);    
 }

 static Future<Response> getClientFrec(String codigo) async {
  // 1) Validación básica
  final trimmed = codigo.trim();
  if (trimmed.isEmpty) {
    return Response(isSuccess: false, message: 'El código está vacío.');
  }

  // 2) Construcción segura de la URL (evita // y hace encoding)
  final base = Constans.getAPIUrl(); // ojo: ¿"Constans" es intencional?
  final uri = Uri.parse(base).replace(
    path: '${Uri.parse(base).path}/api/Clientes/GetClientFrecuenteByCodigoFrecuente/$trimmed',
  );

  final client = http.Client();
  try {
    final resp = await client
        .get(
          uri,
          headers: const {
            'accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    // 3) Manejo de status codes
    if (resp.statusCode == 204) {
      return Response(isSuccess: false, message: 'Sin contenido (204).');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      // intenta extraer mensaje legible si el backend lo manda en JSON
      final msg = _bestEffortMessage(resp.body);
      return Response(isSuccess: false, message: 'HTTP ${resp.statusCode}: $msg');
    }

    // 4) Cuerpo vacío / no JSON
    if (resp.body.isEmpty) {
      return Response(isSuccess: false, message: 'Respuesta vacía del servidor.');
    }

    // 5) Parseo tolerante
    final decoded = jsonDecode(resp.body);

    // Permite backend que devuelva objeto o lista con un solo objeto
    final dynamic obj = (decoded is List && decoded.isNotEmpty) ? decoded.first : decoded;

    if (obj == null || obj is! Map<String, dynamic>) {
      return Response(isSuccess: false, message: 'Formato inesperado de respuesta.');
    }

    final cliente = Cliente.fromJson(obj);
    return Response(isSuccess: true, result: cliente);

  } on TimeoutException {
    return Response(isSuccess: false, message: 'Tiempo de espera agotado.');
  } on SocketException {
    return Response(isSuccess: false, message: 'Sin conexión a Internet o host no alcanzable.');
  } on FormatException catch (e) {
    return Response(isSuccess: false, message: 'JSON inválido: ${e.message}');
  } on HttpException catch (e) {
    return Response(isSuccess: false, message: 'Error HTTP: ${e.message}');
  } catch (e) {
    return Response(isSuccess: false, message: 'Error inesperado: $e');
  } finally {
    client.close();
  }
}

static String _bestEffortMessage(String body) {
  try {
    final d = jsonDecode(body);
    if (d is Map && d['message'] is String) return d['message'] as String;
    if (d is Map && d['error'] is String) return d['error'] as String;
  } catch (_) {
    // body no era JSON; devolvemos texto plano truncado
  }
  final plain = body.replaceAll(RegExp(r'\s+'), ' ');
  return plain.length > 300 ? '${plain.substring(0, 300)}…' : plain;
}



  static Future<Response> getClienteFromHacienda(String document) async {
  final doc = document.trim();
  if (doc.isEmpty) {
    return Response(isSuccess: false, message: 'Debe indicar un documento.');
  }

  try {
   
      final url = Uri.parse('${Constans.getAPIUrl()}/api/Clientes/buscar/$doc');
    final resp = await http.get(
      url,
      headers: const {
        'accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    final status = resp.statusCode;
    final body = resp.body;

    // Errores HTTP
    if (status >= 400) {
      String message;
      try {
        final j = jsonDecode(body);
        // intenta sacar "message" del JSON si existe, si no, usa el body tal cual
        message = (j is Map && j['message'] is String)
            ? j['message'] as String
            : (body.isEmpty ? 'Error $status' : body);
      } catch (_) {
        message = body.isEmpty ? 'Error $status' : body;
      }
      return Response(isSuccess: false, message: message);
    }

    if (body.isEmpty) {
      return Response(isSuccess: false, message: 'Respuesta vacía del servidor.');
    }

    final decoded = jsonDecode(body);
    if (decoded == null || decoded is! Map<String, dynamic>) {
      return Response(isSuccess: false, message: 'Formato JSON inválido.');
    }

    // Compatibilidad: si viene de Hacienda (tipoIdentificacion) usa fromHaciendaJson,
    // si viene como ClienteApi (con llaves de tu dominio), usa fromJson.
    late Cliente cliente;
    if (decoded.containsKey('tipoIdentificacion')) {
      cliente = Cliente.fromHaciendaJson(decoded);
    } else {
      cliente = Cliente.fromJson(decoded);
    }

    // Asegura documento (el backend podría no retornarlo)
    cliente.documento = doc;

    // El backend no trae email/teléfono en este paso: los dejas vacíos para completar luego
    cliente.email = cliente.email; // por si fromJson lo trae vacío
    cliente.telefono = cliente.telefono;

    return Response(isSuccess: true, result: cliente);
  } on TimeoutException {
    return Response(isSuccess: false, message: 'Tiempo de espera agotado al consultar el servicio.');
  } catch (e) {
    return Response(isSuccess: false, message: 'Error inesperado: $e');
  }
}

  static Future<Response> editEmail(String id, Map<String, dynamic> request) async {
        
    var url = Uri.parse('${Constans.getAPIUrl()}/api/Users/$id');
    var response = await http.put(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',        
      },
      body: jsonEncode(request)
    );
     
    if(response.statusCode>= 400){
      return Response(isSuccess: false, message: response.body);
    }
    return Response(isSuccess: true);
  }

static Future<Response> put(String controller, String id, Map<String, dynamic> request) async {
        
    var url = Uri.parse('${Constans.getAPIUrl()}/api/$controller/$id');
    var response = await http.put(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',        
      },
      body: jsonEncode(request)
    );
     
    if(response.statusCode>= 400){
      return Response(isSuccess: false, message: response.body);
    }
    return Response(isSuccess: true);
  }

static Future<Response> post(String controller, Map<String, dynamic> request) async {        
    var url = Uri.parse('${Constans.getAPIUrl()}/$controller');
    var response = await http.post(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',       
      },
      body: jsonEncode(request)
    );    
     
    if(response.statusCode >= 400){
      return Response(isSuccess: false, message: response.body);
    }     
     return Response(isSuccess: true, result: response.body, );
  }

  static Future<Response> postNoRequest(String controller) async {        
    var url = Uri.parse('${Constans.getAPIUrl()}/$controller');
    var response = await http.post(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',       
      },      
    );    

    if(response.statusCode >= 400){
      return Response(isSuccess: false, message: response.body);
    }     
     return Response(isSuccess: true, result: response.body);
  }

static Future<Response> delete(String controller, String id) async { 
    
    var url = Uri.parse('${Constans.getAPIUrl()}$controller$id');
    var response = await http.delete(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',       
      },
    );

    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: response.body);
    }

    return Response(isSuccess: true);
  }

 

   static Future<Response> getClientesPromo() async {
   var url = Uri.parse('${Constans.getAPIUrl()}/api/TransaccionesApi/GetClientesPromo');
    var response = await http.get(
      url,
      headers: {
        'content-type' : 'application/json',
        'accept' : 'application/json',
      },        
    );
    var body = response.body;
    if (response.statusCode >= 400) {
      return Response(isSuccess: false, message: body);
    }
    List<ClientePromo> clientes =[];
    var decodedJson = jsonDecode(body);
     if(decodedJson != null){
      for (var item in decodedJson){
        clientes.add(ClientePromo.fromJson(item));
      }
     }
     return Response(isSuccess: true, result: clientes);    
 }

  static Future<Response> syncActividades(String documento, {String tipoCliente = "Contado"}) async {
      var url = Uri.parse('${Constans.getAPIUrl()}/api/Clientes/actividades/sincronizar');

      final body = {
        "numeroDocumento": documento,
        "tipoCliente": tipoCliente,
      };

      try {
        final response = await http.post(
          url,
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode >= 400) {
          return Response(isSuccess: false, message: response.body);
        }

        var decodedJson = jsonDecode(response.body);
        Cliente cliente = Cliente.fromJson(decodedJson);

        return Response(isSuccess: true, result: cliente);
      } catch (e) {
        return Response(isSuccess: false, message: "Exception: ${e.toString()}");
      }
  }
  static String get _base => Constans.getAPIUrl();

  static Future<Response> syncActividadesCredito(String documento) async {
    
    final doc = Uri.encodeComponent(documento.trim());
    final url = Uri.parse('$_base/api/Clientes/clientes/$doc/actividades/credito');

    try {
      final resp = await http.post(
        url,
        headers: const {
          'content-type': 'application/json',
          'accept': 'application/json',
        },
      );

      if (resp.statusCode >= 400) {
        String msg;
        try {
          final body = jsonDecode(resp.body);
          msg = body is Map && body['message'] is String ? body['message'] : resp.body;
        } catch (_) {
          msg = resp.body;
        }
        return Response(isSuccess: false, message: msg);
      }

      final decoded = jsonDecode(resp.body);
      final cliente = Cliente.fromJson(decoded);
      return Response(isSuccess: true, result: cliente);
    } catch (e) {
      return Response(isSuccess: false, message: "Exception: ${e.toString()}");
    }
  }
}

