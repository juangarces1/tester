import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/Models/transferencia.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/Sinpes/lista_sinpes_screen.dart';
import 'package:tester/Screens/Transfers/transfer_screen.dart';
import 'package:tester/constans.dart';
import 'package:provider/provider.dart';


class FormPago extends StatefulWidget {
  @override
  // ignore: overridden_fields
  final GlobalKey<FormPagoState> key;
  final int index;
  final Color fontColor;

  final String ruta;
  const FormPago({required this.key,
   required this.index,
   required this.fontColor,
  
   required this.ruta,
   }) : super(key: key);

  @override
   FormPagoState createState() => FormPagoState();
}

class FormPagoState extends State<FormPago> {
   late Invoice factura;
   late TextEditingController  cashController;
   late TextEditingController  transferController;    
   late TextEditingController  bacController;
   late TextEditingController  bnController;
   late TextEditingController  davController;
   late TextEditingController  sctiaController;
   late TextEditingController  pointsController;
   late TextEditingController  dollarController;
   late TextEditingController  chequeController;
   late TextEditingController  cuponController;
   late TextEditingController  sinpeController;
   
  @override
  void initState() {
    super.initState();
    //  cashController.text= widget.factura.formPago!.totalEfectivo.toInt().toString();
       factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
       cashController = TextEditingController(text: factura.formPago!.monedaEfectivo);
       transferController = TextEditingController(text: factura.formPago!.monedaTransfer);
       bacController = TextEditingController(text: factura.formPago!.monedaBac);     
       bnController = TextEditingController(text: factura.formPago!.monedaBn);
       davController = TextEditingController(text: factura.formPago!.monedaDav);
       sctiaController = TextEditingController(text: factura.formPago!.monedaSctia);
       pointsController = TextEditingController(text: factura.formPago!.monedaPuntos);
       dollarController = TextEditingController(text: factura.formPago!.monedaDollar);
       chequeController = TextEditingController(text: factura.formPago!.monedaCheque);
       cuponController = TextEditingController(text: factura.formPago!.monedaCupones);  
       sinpeController = TextEditingController(text: factura.formPago!.monedaSinpe);


   // setValues();
 
  }

  @override
  void dispose() {
    cashController.dispose();
    transferController.dispose();
    bacController.dispose();
    bnController.dispose();
    davController.dispose();
    sctiaController.dispose();
    pointsController.dispose();
    dollarController.dispose();
    chequeController.dispose(); 
    cuponController.dispose();
    sinpeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   return  Container(
      decoration: BoxDecoration(
        color: kNewborder,
        border: Border.all(color: kTextColorWhite, width: 1),
        borderRadius: BorderRadius.circular(10),
        
      ),
     
      child: ExpansionTile(
        title: Text(
            'Seleccione la Forma de Pago',
            style: TextStyle(
              color: widget.fontColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        iconColor:widget. fontColor,
        collapsedIconColor: widget.fontColor,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 235, 230, 236),
              gradient: const LinearGradient(
                colors: [kBlueColorLogo, Color.fromARGB(255, 255, 255, 255)],
                begin: Alignment.centerRight,
                end: Alignment(0.95, 0.0),
                tileMode: TileMode.clamp
              ),
              border: Border.all(
                color: kSecondaryColor,
                width: 1,
              ),
            ),
            child: Column(
              children: [
              
                const SizedBox(height: 10,),   
                _showBacAndBn(),    
                const SizedBox(height: 10,),                
                _showScotiaDav(),   
                const SizedBox(height: 10,),
                _showCashDollar(),
                const SizedBox(height: 10,),
                _showPointTransfers(),            
                const SizedBox(height: 10,),
                _showChequeCupones(),                  
                const SizedBox(height: 10,), 
                _showSinpeRefresh(),
                const SizedBox(height: 10,),                 
              ],
            ),
          )
        ],
      ),
    );

  }

  Widget _showCashDollar() {
    return
      Container(
        padding: const EdgeInsets.only(left: 20.0, right: 25),
        child: Row(
          children: [
            Flexible(
              child: TextField(   
                
                controller: cashController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                decoration: const InputDecoration(
                  hintText: 'Ingrese el Monto',
                  labelText: 'Efectivo',  
                ),
                onChanged: (value) {            
                 if (value.isNotEmpty){ 
                   setState(() {    
                     factura.formPago!.totalEfectivo = double.parse(value);
                     FacturaService.updateFactura(context, factura);
                     if(factura.saldo < 0){                 
                       factura.formPago!.totalEfectivo = 0;                        
                       cashController.text= value.toString();
                        FacturaService.updateFactura(context, factura);
                       Fluttertoast.showToast(
                        msg: " La cantidad es superior al saldo, por favor vuelva a ingresarla",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0
                      ); 
                     }

                  });  
                 
                }         
                },
              ),
            ),
             SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goCashAll,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                     color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/COLON.jpg'),
                  
                  )
                ),
              )
              ),
            ),
             const SizedBox(width: 10,),
               Flexible(
              child: TextField(   
                controller: dollarController,    
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                decoration: const InputDecoration(
                  hintText: 'Ingrese el Monto',
                  labelText: 'Dollares',            
                  
                
                ),
                onChanged: (value) {            
                 if (value.isNotEmpty){ 
                   setState(() {     
                         
                     factura.formPago!.totalDollars = double.parse(value);
                        FacturaService.updateFactura(context, factura);
                                    
                     if(factura.saldo < 0){                 
                       factura.formPago!.totalDollars = 0;                     
                          FacturaService.updateFactura(context, factura); 
                       dollarController.text= value.toString();
                       Fluttertoast.showToast(
                        msg: "La cantidad es superior al saldo, por favor vuelva a ingresarla",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0
                      ); 
                     }
                  });  
                }         
                },
              ),
            ),
             SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goDollar,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/dollar.png'),
                  
                  )
                ),
              )
              ),
            ),

          ],
        ),
      );
  }

  Widget _showBacAndBn() {
    return
      Container(
        padding: const EdgeInsets.only(left: 20.0, right: 25),
        child: Row(
          children: [
            Flexible(
              child: TextField(  
                controller: bacController,      
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ingrese el Monto',
                  labelText: 'Tarjeta Bac',          
                          
                ),
               onChanged: (value) {            
                 if (value.isNotEmpty){ 
                   setState(() {     
                              
                     factura.formPago!.totalBac = double.parse(value);
                       FacturaService.updateFactura(context, factura);
                                   
                     if(factura.saldo < 0){                  
                       factura.formPago!.totalBac = 0;  
                       FacturaService.updateFactura(context, factura);
                       bacController.text= value.toString();               
                       Fluttertoast.showToast(
                        msg: " La cantidad es superior al saldo, por favor vuelva a ingresarla",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0
                      ); 
                     }
                  });  
                }         
                },
              ),
            ),

             SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goTarjetaBacAll,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/Bac.png'),
                  
                  )
                ),
              )
              ),
            ),
            const SizedBox(width: 10,),
             Flexible(
              child: TextField(
                controller: bnController,        
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ingrese el Monto',
                  labelText: 'Tarjeta BN',         
                           
                ),
               onChanged: (value) {            
                 if (value.isNotEmpty){ 
                   setState(() {     
                          
                     factura.formPago!.totalBn = double.parse(value);
                
                     FacturaService.updateFactura(context ,factura);
                     int valor= int.parse(value);
                     if(factura.saldo < 0){                 
                       factura.formPago!.totalBn = 0;
                     
                       FacturaService.updateFactura(context, factura);
                       bnController.text = valor.toString();                
                       Fluttertoast.showToast(
                        msg: " La cantidad es superior al saldo, por favor vuelva a ingresarla",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0
                      ); 
                     }
                  });  
                }         
                },
              ),
            ),

             SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goTarjetaBN,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                     color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/BN.jpg'),
                  
                  )
                ),
              )
              ),
            ),
          
          ],
        ),
      );
  }
  
  Widget _showPointTransfers(){
       if(factura.formPago!.totalTransfer > 0){
         transferController.text = factura.formPago!.monedaTransfer; 
       }
   
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 25),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              readOnly: true,   
              controller: pointsController,    
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              decoration: const InputDecoration(
                hintText: 'Select...',
                labelText: 'Puntos', 
              ),          
            ),
          ),
          SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goPoints,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/points.jpg'),
                  
                  )
                ),
              )
              ),
            ),
        const SizedBox(width: 10,),
           Flexible(
              child: TextField(  
                readOnly: true, 
                controller: transferController,    
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Select...',
                  labelText: 'Transferencias', 
                ),          
              ),
            ),
            SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goTransfers,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                     color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/transferencia.png'),
                  
                  )
                ),
              )
              ),
            ),
      
        ],
      ),
    );
  
    
  }
  
  Widget _showScotiaDav() {
    return
      Container(
          padding: const EdgeInsets.only(left: 20.0, right: 25),
        child: Row(
          children: [
            Flexible(
              child: TextField(   
                controller: sctiaController,    
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                decoration: const InputDecoration(
                  hintText: 'Ingrese el Monto',
                  labelText: 'Tarjeta Sctia',          
                  
                
                ),
                onChanged: (value) {            
                 if (value.isNotEmpty){ 
                   setState(() { 
                     factura.formPago!.totalSctia = double.parse(value);
                     
                        FacturaService.updateFactura(context, factura);        
                     if(factura.saldo < 0){                 
                        factura.formPago!.totalSctia = 0;
                    
                       FacturaService.updateFactura(context, factura);
                        sctiaController.text= value.toString();
                        Fluttertoast.showToast(
                          msg: " La cantidad es superior al saldo, por favor vuelva a ingresarla",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0
                        ); 
                     }
                  });  
                }         
                },
              ),
            ),

           SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goTarjetaScotia,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                       color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/Scottia.png'),
                  
                  )
                ),
              )
              ),
            ),
           const SizedBox(width: 10,),
           Flexible(
              child: TextField(   
                controller: davController,    
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                decoration: const InputDecoration(
                  hintText: 'Ingrese el Monto',
                  labelText: 'Tarjeta Dav',            
                  
                
                ),
                onChanged: (value) {            
                 if (value.isNotEmpty){ 
                   setState(() {  
                     factura.formPago!.totalDav = double.parse(value);                    
                     FacturaService.updateFactura(context, factura);               
                     if(factura.saldo < 0){                 
                        factura.formPago!.totalDav = 0;
                     
                        FacturaService.updateFactura(context, factura);
                        davController.text= value.toString();
                        Fluttertoast.showToast(
                          msg: "La cantidad es superior al saldo, por favor vuelva a ingresarla",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0
                        ); 
                     }
                  });  
                }         
                },
              ),
            ),
             SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goTarjetaDav,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                       color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/davicasa.png'),                  
                  )
                ),
              )
              ),
            ),
          ],
        ),
      );
  }
  
  Widget _showChequeCupones() {
    return
      Container(
        padding: const EdgeInsets.only(left: 20.0, right: 25),
        child: Row(
          children: [
            Flexible(
              child: TextField(   
                controller: chequeController,    
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                decoration: const InputDecoration(
                  hintText: 'Ingrese el Monto',
                  labelText: 'Cheque',            
                  
                
                ),
                onChanged: (value) {            
                 if (value.isNotEmpty){ 
                   setState(() {     
                         
                     factura.formPago!.totalCheques = double.parse(value);
                    
                      FacturaService.updateFactura(context, factura);           
                     if(factura.saldo < 0){                 
                       factura.formPago!.totalCheques = 0;
                       FacturaService.updateFactura(context, factura);
                      
                       cashController.text= value.toString();
                       Fluttertoast.showToast(
                        msg: "La cantidad es superior al saldo, por favor vuelva a ingresarla",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0
                      ); 
                     }
                  });  
                }         
                },
              ),
            ),
             SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goCheque,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/CHEQUE.jpg'),
                  
                  )
                ),
              )
              ),
            ),
            const SizedBox(width: 10,),
             Flexible(
              child: TextField(   
                controller: cuponController,    
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                decoration: const InputDecoration(
                  hintText: 'Ingrese la cantidad',
                  labelText: 'Cupones',            
                  
                
                ),
                onChanged: (value) {            
                 if (value.isNotEmpty){ 
                   setState(() {     
                         
                     factura.formPago!.totalCupones = double.parse(value);
                   
                     FacturaService.updateFactura(context, factura);          
                     if(factura.saldo < 0){                 
                       factura.formPago!.totalCupones = 0;                      
                       FacturaService.updateFactura(context, factura);
                       cuponController.text= value.toString();
                       Fluttertoast.showToast(
                        msg: "La cantidad es superior al saldo, por favor vuelva a ingresarla",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0
                      ); 
                     }
                  });  
                }         
                },
              ),
            ),
             SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: _goCupon,
              child: AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kTextColorBlack.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Image(
                    image: AssetImage('assets/CUPONES.png'),
                  
                  )
                ),
              )
              ),
            ),
          ],
        ),
      );
  }

  Widget _showSinpeRefresh() {
      if(factura.formPago!.totalSinpe > 0){
        sinpeController.text = factura.formPago!.totalSinpe.toInt().toString(); 
      }
    return
      Align(
         alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.52,
        
          child: Padding(
             padding: const EdgeInsets.only(left: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                
             Flexible(
                  child: TextField(  
                    readOnly: true, 
                    controller: sinpeController,    
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Select...',
                      labelText: 'Sinpes',            
                              
                    ),          
                  ),
                ),
                SizedBox(
                width: 60,
                child: GestureDetector(
                  onTap: _goSinpes,
                  child: AspectRatio(
                    aspectRatio: 1.02,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: kTextColorBlack.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Image(
                        image: AssetImage('assets/sinpe.png'),
                      
                      )
                    ),
                  )
                  ),
                ),
                const SizedBox(width: 20,),
                            
              ],
            ),
          ),
        ),
      );
  }

  void _goCashAll() {
    if(factura.saldo<=0){        
         Fluttertoast.showToast(
            msg: "La factura ya no tiene saldo",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
    }
    
    setState(() {
     
      factura.formPago!.totalEfectivo += factura.saldo;
      cashController.text= factura.formPago!.totalEfectivo.toInt().toString();
      
       //  onSaldoChanged(factura.formPago!.saldo);
    
    });
      FacturaService.updateFactura(context, factura);
  }

  void _goTarjetaBacAll() {
    if(factura.saldo<=0){
        Fluttertoast.showToast(
            msg: "La factura ya no tiene saldo",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
    }
    
    setState(() {
     
      factura.formPago!.totalBac += factura.saldo;
      bacController.text=factura.formPago!.totalBac.toInt().toString();
     FacturaService.updateFactura(context, factura);
    });
  }

  void _goTarjetaBN() {
    if(factura.saldo<=0){
        Fluttertoast.showToast(
            msg: "La factura ya no tiene saldo",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
    }
    
     setState(() {
     
      factura.formPago!.totalBn += factura.saldo;
      bnController.text=factura.formPago!.totalBn.toInt().toString();
      FacturaService.updateFactura(context,factura);
    });
  }

  void _goTarjetaScotia() {
    if(factura.saldo<=0){
        Fluttertoast.showToast(
            msg: "La factura ya no tiene saldo",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
    }
    
    setState(() {       
        factura.formPago!.totalSctia += factura.saldo;
        sctiaController.text= factura.formPago!.totalSctia.toInt().toString();
        FacturaService.updateFactura(context, factura);
    });
  }

  void _goTarjetaDav() {
    if(factura.saldo<=0){
        Fluttertoast.showToast(
            msg: "La factura ya no tiene saldo",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
    }
    
    setState(() {
     
      factura.formPago!.totalDav +=factura.saldo;
      davController.text= factura.formPago!.totalDav.toInt().toString();
  
      FacturaService.updateFactura(context, factura);
    });
  }

  void _goDollar() {
    if(factura.saldo<=0){
        Fluttertoast.showToast(
            msg: "La factura ya no tiene saldo",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
    }    
    setState(() {
      
      factura.formPago!.totalDollars += factura.saldo;
      dollarController.text= factura.formPago!.totalDollars.toInt().toString();
      FacturaService.updateFactura(context, factura);     
    });
  }

  void _goCheque() {
    if(factura.saldo<=0){
        Fluttertoast.showToast(
            msg: "La factura ya no tiene saldo",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
    }    
    setState(() {  
      factura.formPago!.totalCheques += factura.saldo;
      chequeController.text= factura.formPago!.totalCheques.toInt().toString();
      FacturaService.updateFactura(context, factura);      
    });
  }

  void _goCupon() {
    if(factura.saldo<=0){
       Fluttertoast.showToast(
            msg: "La factura ya no tiene saldo",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
    }    
    setState(() {
    
      factura.formPago!.totalCupones += factura.saldo;
      cuponController.text= factura.formPago!.totalCupones.toInt().toString();
      FacturaService.updateFactura(context, factura);
    });
  }

  void _goPoints() {
     if(factura.saldo<=0){
        Fluttertoast.showToast(
          msg: "La factura ya no tiene saldo",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
        ); 
        return;
     }    
    
     if(factura.formPago!.clientePuntos.nombre.isEmpty){
       Fluttertoast.showToast(
            msg: "Seleccione el Cliente Frecuente",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
     }   

     if(factura.formPago!.clientePuntos.puntos==0){
       Fluttertoast.showToast(
            msg: "El cliente no tiene puntos",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
          ); 
        return;
     } 

      if(factura.saldo < factura.formPago!.clientePuntos.puntos){       
          factura.formPago!.totalPuntos = factura.saldo;  
      }
      else{
        factura.formPago!.totalPuntos =  factura.formPago!.clientePuntos.puntos.toDouble();
      }

      setState(() {          
           pointsController.text= factura.formPago!.totalPuntos.toInt().toString();           
           FacturaService.updateFactura(context, factura);
      });
    
  }
  
  void _goTransfers()  {   
   // transferController.text='';i
    setState(() {
             
      
       factura.formPago!.transfer.totalTransfer=factura.saldo;
        FacturaService.updateFactura(context, factura);
    });
 
   

  
   Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransferScreen(index: widget.index,))
    );
   
}
  
 
  void setValues() {
    setState(() {
      if(factura.formPago!.totalEfectivo>0){
        cashController.text= factura.formPago!.totalEfectivo.toInt().toString();
      }
      if(factura.formPago!.totalDollars>0){
        dollarController.text= factura.formPago!.totalDollars.toInt().toString();
      }
      if(factura.formPago!.totalCheques>0){
        chequeController.text= factura.formPago!.totalCheques.toInt().toString();
      }
      if(factura.formPago!.totalCupones>0){
        cuponController.text= factura.formPago!.totalCupones.toInt().toString();
      }
      if(factura.formPago!.totalPuntos>0){
        pointsController.text= factura.formPago!.totalPuntos.toInt().toString();
      }
      if(factura.formPago!.totalTransfer>0){
        transferController.text= factura.formPago!.totalTransfer.toInt().toString();
      }
      if(factura.formPago!.totalBac>0){
        bacController.text= factura.formPago!.totalBac.toInt().toString();
      }
      if(factura.formPago!.totalBn>0){
        bnController.text= factura.formPago!.totalBn.toInt().toString();
      }
      if(factura.formPago!.totalDav>0){
        davController.text= factura.formPago!.totalDav.toInt().toString();
      }
      if(factura.formPago!.totalSctia>0){
        sctiaController.text= factura.formPago!.totalSctia.toInt().toString();
      }
        if(factura.formPago!.totalSinpe>0){
        sctiaController.text= factura.formPago!.totalSctia.toInt().toString();
      }
     FacturaService.updateFactura(context, factura);
    });
  }

  void _goSinpes() {
    sinpeController.text='';
   
   
     Navigator.push(context,
       MaterialPageRoute(
         builder: (context) => ListaSinpesScreen(
           index: widget.index,         
          
         )));
  }
  
  goRefresh() {
    setState(() {
      factura.formPago!.totalBac=0;
      factura.formPago!.totalBn=0;
      factura.formPago!.totalCheques=0;
      factura.formPago!.totalCupones=0;
      factura.formPago!.totalDav=0;
      factura.formPago!.totalDollars=0;
      factura.formPago!.totalEfectivo=0;
      factura.formPago!.totalPuntos=0;
      factura.formPago!.totalSctia=0;
      factura.formPago!.totalTransfer=0;
      factura.formPago!.transfer.totalTransfer=0;
      factura.formPago!.totalSinpe=0;
      factura.formPago!.transfer = Transferencia(cliente: Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos: 0, codigo: '', telefono: ''), transfers: [], monto: 0, totalTransfer: 0);
      factura.formPago!.clientePuntos = Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos: 0, codigo: '', telefono: '');     
      factura.formPago!.clienteFactura = Cliente(nombre: '', documento: '', codigoTipoID: '', email: '', puntos: 0, codigo: '', telefono: '');     
      factura.formPago!.sinpe = Sinpe(numFact: '', fecha: DateTime.now(), id: 0, idCierre: 0, activo: 0, monto: 0, nombreEmpleado: '', nota: '', numComprobante: '');
    
     
      sinpeController.text='';
      cashController.text='';
      dollarController.text='';
      chequeController.text='';
      cuponController.text='';
      pointsController.text='';
      transferController.text='';
      bacController.text='';
      bnController.text='';
      davController.text='';
      sctiaController.text='';
      FacturaService.updateFactura(context, factura);
      
    });
  }
 


}