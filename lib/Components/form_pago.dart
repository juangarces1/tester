import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/Models/FuelRed/transferencia.dart';
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
  final ExpansibleController expansibleController; // 👈 nuevo

  const FormPago({required this.key,
   required this.index,
   required this.fontColor,  
   required this.ruta,
   required this.expansibleController,
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

  static const TextStyle _fieldTextStyle = TextStyle(
    color: kNewtextPri,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const double _shortcutSize = 56;
   
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

  BoxDecoration _shortcutDecoration() {
    return BoxDecoration(
      color: kNewborder,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kNewborder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildImageShortcut(String asset, VoidCallback onTap) {
    return SizedBox(
      width: _shortcutSize,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: _shortcutSize,
          decoration: _shortcutDecoration(),
          padding: const EdgeInsets.all(10),
          child: Image.asset(asset),
        ),
      ),
    );
  }

  Widget _buildIconShortcut(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: _shortcutSize,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: _shortcutSize,
          decoration: _shortcutDecoration(),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: kNewtextPri,
            size: 26,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  
   
    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: kNewsurfaceHi,
      labelStyle: const TextStyle(
        color: kNewtextPri,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: kNewtextMut),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewborder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewgreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewred),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewred),
      ),
    );

   

   return Container(
    decoration: BoxDecoration(
      color: kNewsurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kNewborder),
      boxShadow: const [ /* ... */ ],
    ),
    child: Theme(
      data: Theme.of(context).copyWith(inputDecorationTheme: inputTheme),
      child: Expansible(
        controller: widget.expansibleController,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        maintainState: true,
        // HEADER: pinta tu cabecera y permite toggle al tocar
        headerBuilder: (context, anim) {
          final isOpen = widget.expansibleController.isExpanded;
          return InkWell(
            onTap: () => isOpen
                ? widget.expansibleController.collapse()
                : widget.expansibleController.expand(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seleccione la Forma de Pago',
                      style: TextStyle(
                        color: widget.fontColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  // Icono que rota con la animación
                  AnimatedRotation(
                    turns: anim.value * 0.5, // 0 → 0°, 1 → 180°
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: widget.fontColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        // BODY: tu contenido actual de pagos
        bodyBuilder: (context, anim) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F141E), Color(0xFF1A2332)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 4),
                _showBacAndBn(),
                const SizedBox(height: 12),
                _showScotiaDav(),
                const SizedBox(height: 12),
                _showCashDollar(),
                const SizedBox(height: 12),
                _showPointTransfers(),
                const SizedBox(height: 12),
                _showChequeCupones(),
                const SizedBox(height: 12),
                _showSinpeRefresh(),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
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
                style: _fieldTextStyle,
                cursorColor: kNewgreen,
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
            const SizedBox(width: 12),
            _buildImageShortcut('assets/COLON.jpg', _goCashAll),
             const SizedBox(width: 10,),
               Flexible(
              child: TextField(   
                style: _fieldTextStyle,
                cursorColor: kNewgreen,
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
            const SizedBox(width: 12),
            _buildImageShortcut('assets/dollar.png', _goDollar),

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
                style: _fieldTextStyle,
                cursorColor: kNewgreen,
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

            const SizedBox(width: 12),
            _buildImageShortcut('assets/Bac.png', _goTarjetaBacAll),
            const SizedBox(width: 10,),
             Flexible(
              child: TextField(
                style: _fieldTextStyle,
                cursorColor: kNewgreen,
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

            const SizedBox(width: 12),
            _buildImageShortcut('assets/BN.jpg', _goTarjetaBN),
          
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
              style: _fieldTextStyle,
              cursorColor: kNewgreen,
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
          const SizedBox(width: 12),
          _buildImageShortcut('assets/points.jpg', _goPoints),
        const SizedBox(width: 12,),
           Flexible(
              child: TextField(  
                style: _fieldTextStyle,
                cursorColor: kNewgreen,
                readOnly: true, 
                controller: transferController,    
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Select...',
                  labelText: 'Transferencias', 
                ),          
              ),
            ),
            const SizedBox(width: 12),
            _buildImageShortcut('assets/transferencia.png', _goTransfers),
      
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
                style: _fieldTextStyle,
                cursorColor: kNewgreen,
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

          const SizedBox(width: 12),
          _buildImageShortcut('assets/Scottia.png', _goTarjetaScotia),
           const SizedBox(width: 10,),
           Flexible(
              child: TextField(   
                style: _fieldTextStyle,
                cursorColor: kNewgreen,
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
            const SizedBox(width: 12),
            _buildImageShortcut('assets/davicasa.png', _goTarjetaDav),
          ],
        ),
      );
  }
  
  Widget _showChequeCupones() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 25),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: chequeController,
              style: _fieldTextStyle,
              cursorColor: kNewgreen,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              decoration: const InputDecoration(
                hintText: 'Ingrese el Monto',
                labelText: 'Cheque',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    factura.formPago!.totalCheques = double.parse(value);
                    FacturaService.updateFactura(context, factura);

                    if (factura.saldo < 0) {
                      factura.formPago!.totalCheques = 0;
                      FacturaService.updateFactura(context, factura);
                      chequeController.text = value.toString();
                      Fluttertoast.showToast(
                        msg: 'La cantidad es superior al saldo, por favor vuelva a ingresarla',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          _buildImageShortcut('assets/CHEQUE.jpg', _goCheque),
          const SizedBox(width: 12),
          Flexible(
            child: TextField(
              controller: cuponController,
              style: _fieldTextStyle,
              cursorColor: kNewgreen,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              decoration: const InputDecoration(
                hintText: 'Ingrese la cantidad',
                labelText: 'Cupones',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    factura.formPago!.totalCupones = double.parse(value);
                    FacturaService.updateFactura(context, factura);
                    if (factura.saldo < 0) {
                      factura.formPago!.totalCupones = 0;
                      FacturaService.updateFactura(context, factura);
                      cuponController.text = value.toString();
                      Fluttertoast.showToast(
                        msg: 'La cantidad es superior al saldo, por favor vuelva a ingresarla',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          _buildImageShortcut('assets/CUPONES.png', _goCupon),
        ],
      ),
    );
  }

Widget _showSinpeRefresh() {
  if (factura.formPago!.totalSinpe > 0) {
    sinpeController.text = factura.formPago!.totalSinpe.toInt().toString();
  }

  return Padding(
    padding: const EdgeInsets.only(left: 20.0, right: 25),
    child: Row(
      children: [
        // Mitad izquierda (TextField + imagen)
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: sinpeController,
                  style: _fieldTextStyle,
                  cursorColor: kNewgreen,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Select...',
                    labelText: 'Sinpes',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildImageShortcut('assets/sinpe.png', _goSinpes),
            ],
          ),
        ),

        // Separación opcional entre las dos mitades
        const SizedBox(width: 12),

        // Mitad derecha (refresh)
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildIconShortcut(Icons.refresh_rounded, goRefresh),
          ),
        ),
      ],
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
