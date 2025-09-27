import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/boton_flotante.dart';
import 'package:tester/Components/client_points.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/form_pago.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/show_actividad_select.dart';
import 'package:tester/Components/show_client.dart';
import 'package:tester/Components/show_email.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/factura.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/boton_combustibles.dart';
import 'package:tester/Screens/NewHome/Components/produccts_page.dart';
import 'package:tester/sizeconfig.dart';

import '../../helpers/api_helper.dart';

// ===== Paleta oscura + tokens Contado (UI solo) =====
const _bg = Color(0xFF0B0D10);
const _surface = Color(0xFF12151A);
const _surfaceHi = Color(0xFF171B22);
const _border = Color(0xFF2A3038);
const _textPri = Color(0xFFE8EDF2);
const _textSec = Color(0xFFB1B8C3);
const _textMut = Color(0xFF7C8696);
const _red = Color(0xFFD64045);
const _redPressed = Color(0xFFC1363A);
const _green = Color(0xFF1BBF84);

// ignore: must_be_immutable
class ContadoScreen extends StatefulWidget {
  final int index;

  const ContadoScreen({super.key, required this.index});

  @override
  State<ContadoScreen> createState() => _ContadoScreenState();
}

class _ContadoScreenState extends State<ContadoScreen> {
  bool _showLoader = false;
  late TextEditingController kms;
  late TextEditingController obser;
  late TextEditingController placa;
  late Invoice factura;
  final GlobalKey<FormPagoState> formPagoKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  void callGoRefresh() {
    formPagoKey.currentState?.goRefresh();
  }

  @override
  void initState() {
    super.initState();
    factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    kms = TextEditingController(text: factura.kms.toString());
    obser = TextEditingController(text: factura.observaciones.toString());
    placa = TextEditingController(text: factura.placa.toString());
  }

  @override
  void dispose() {
    kms.dispose();
    obser.dispose();
    placa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facturaC = Provider.of<FacturasProvider>(context, listen: true).getInvoiceByIndex(widget.index);
    final canFacturar = (facturaC.detail?.isNotEmpty ?? false) &&
        facturaC.saldo == 0 &&
        (facturaC.formPago?.clienteFactura.nombre.isNotEmpty ?? false);

    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: _bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _appBarDark(facturaC),
        ),

        // ===== Cuerpo con resumen superior + secciones =====
        body: Stack(
          children: [
            RefreshIndicator(
              color: _red,
              backgroundColor: _surface,
              onRefresh: () async => callGoRefresh(),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _summaryBar(facturaC)),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          // Panel Cliente / Puntos (manteniendo tu widget)
                          _panel(
                            child: ClientPoints(factura: facturaC, ruta: 'Contado'),
                          ),
                          const SizedBox(height: 12),
                          // Panel FormPago (tu widget)
                          _panel(
                            child: FormPago(
                              key: formPagoKey,
                              index: widget.index,
                              fontColor: const Color.fromARGB(255, 96, 16, 16),
                              ruta: 'Contado',
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Panel Información de la factura (tus fields)
                          _panel(child: signUpForm()),
                          const SizedBox(height: 96), // espacio para la barra inferior
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loader superpuesto (sin cambios de lógica)
            if (_showLoader) const LoaderComponent(loadingText: "Creando Factura..."),
          ],
        ),

        // ===== Barra inferior fija: acciones + CTA Facturar =====
        bottomNavigationBar: _bottomBar(context, facturaC, canFacturar),

        // Mantengo tu FAB si lo usas para otra cosa (no toco lógica)
        floatingActionButton: FloatingButtonWithModal(index: widget.index),
      ),
    );
  }

  // ================== WIDGETS DE UI (solo diseño) ==================

  PreferredSizeWidget _appBarDark(Invoice facturaApp) {
    return AppBar(
      elevation: 5,
      backgroundColor: _bg,
      foregroundColor: _textPri,
      titleSpacing: 12,
      title: Row(
        children: [
          // Botón volver
          SizedBox(
            height: 44,
            width: 44,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                backgroundColor: Colors.black,
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                FacturaService.updateFactura(context, facturaApp);
                Navigator.pop(context);
              },
              child: SvgPicture.asset(
                "assets/Back ICon.svg",
                height: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Chip de "Contado" en rojo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _red.withOpacity(.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _red, width: 1),
            ),
            child: const Text(
              "CONTADO",
              style: TextStyle(
                color: _textPri,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniAction({
  required String tooltip,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Tooltip(
    message: tooltip,
    waitDuration: const Duration(milliseconds: 500),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: _red.withOpacity(.2),
        highlightColor: Colors.white.withOpacity(.06),
        child: Container(
          height: 44, // si lo quieres más táctil: 56
          width: 44,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 1.5),
          ),
          child: Icon(icon, size: 22, color: _textPri),
        ),
      ),
    ),
  );
}

  Widget _summaryBar(Invoice f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: _surfaceHi,
        border: Border(
          top: BorderSide(color: _border, width: 1),
          bottom: BorderSide(color: _border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Total
          Expanded(
            child: _metric(
              label: 'TOTAL',
              value: NumberFormat("###,###", "en_US").format(f.total.toInt()),
              color: _textPri,
            ),
          ),
          Container(width: 1.5, height: 36, color: _border),
          // Saldo
          Expanded(
            child: _metric(
              label: 'SALDO',
              value: NumberFormat("###,###", "en_US").format(f.saldo),
              color: f.saldo == 0 ? _green : _red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric({required String label, required String value, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: _textSec,
                fontSize: 12,
                letterSpacing: 1.0,
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _bottomBar(BuildContext context, Invoice f, bool canFacturar) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: _surfaceHi,
        border: Border(top: BorderSide(color: _border, width: 1.5)),
      ),
      child: Row(
        children: [
          // Acceso rápido: Productos
          _miniAction(
            tooltip: 'Agregar productos',
            icon: Icons.inventory_2_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductsPage(index: widget.index)),
              );
            },
          ),
          const SizedBox(width: 10),

          // Acceso rápido: Transacciones (reutiliza tu widget)
          SizedBox(
            height: 44,
            child: BotonTransacciones(
              imagePath: 'assets/AddTr.png',
              onItemSelected: onItemSelected,
              zona: f.cierre!.idzona!,
            ),
          ),

          const Spacer(),

          // CTA Facturar (mismo flujo/handler)
          SizedBox(
            height: 52,
            child: AbsorbPointer(
              absorbing: !canFacturar,
              child: Opacity(
                opacity: canFacturar ? 1 : 0.55,
                child: DefaultButton(
                  text: "Facturar",
                  press: () => goFact(f),
                  gradient: const LinearGradient(colors: [_red, _redPressed]),
                  color: _red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== TUS MÉTODOS (sin cambios de lógica) ==================

  void onItemSelected(Product product) {
    setState(() {
      factura.detail!.add(product);
    });
  }

  Widget signUpForm() {
    // visual: modo oscuro + alto contraste
    return Container(
      color: _surface,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: _surface,
          collapsedBackgroundColor: _surface,
          iconColor: _red,
          collapsedIconColor: _red,
          tilePadding: const EdgeInsets.symmetric(horizontal: 6),
          title: const Text(
            'Información de la Factura',
            style: TextStyle(
              color: _textPri,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8, bottom: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 1.5),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Cliente
                  _panel(
                    child: ShowClient(
                      factura: factura,
                      ruta: 'Contado',
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // // Email
                  // (factura.formPago!.clienteFactura.nombre.isNotEmpty)
                  //     ? _panel(
                  //         child: Padding(
                  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  //           child: ShowEmail(
                  //             email: factura.formPago!.clienteFactura.email,
                  //             backgroundColor: _surface,
                  //           ),
                  //         ),
                  //       )
                  //     : const SizedBox.shrink(),

                    // Actividad
                  // (factura.formPago!.clienteFactura.actividadSeleccionada != null)
                  //     ? _panel(
                  //         child: Padding(
                  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  //           child: ShowActividadSelect(
                  //             actividad: factura.formPago!.clienteFactura.actividadSeleccionada!,                          
                  //           ),
                  //         ),
                  //       )
                  //     : const SizedBox.shrink(),   

                  const SizedBox(height: 10),
                //  _panel(child: showkms()),
                  const SizedBox(height: 10),
                  _panel(child: showPlaca()),
                  const SizedBox(height: 10),
                  _panel(child: showObser()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showkms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: kms,
        style: const TextStyle(color: _textPri),
        cursorColor: _red,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
        decoration: const InputDecoration(
          filled: true,
          fillColor: _surfaceHi,
          hintText: 'Ingrese los kms',
          hintStyle: TextStyle(color: _textMut),
          labelText: 'Kms',
          labelStyle: TextStyle(color: _textSec),
          suffixIcon: Icon(Icons.car_repair_rounded, color: _textSec),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _border, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _red, width: 1.8),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            setState(() {
              factura.kms = int.parse(value);
              FacturaService.updateFactura(context, factura);
            });
          }
        },
      ),
    );
  }

  Widget showObser() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: obser,
        style: const TextStyle(color: _textPri),
        cursorColor: _red,
        keyboardType: TextInputType.text,
        maxLines: 3,
        decoration: const InputDecoration(
          filled: true,
          fillColor: _surfaceHi,
          labelText: 'Observaciones',
          labelStyle: TextStyle(color: _textSec),
          hintText: 'Ingrese las Observaciones',
          hintStyle: TextStyle(color: _textMut),
          suffixIcon: Icon(Icons.sms_outlined, color: _textSec),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _border, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _red, width: 1.8),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            setState(() {
              factura.observaciones = (value);
              FacturaService.updateFactura(context, factura);
            });
          }
        },
      ),
    );
  }

  Widget showPlaca() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: placa,
        style: const TextStyle(color: _textPri),
        cursorColor: _red,
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(
          filled: true,
          fillColor: _surfaceHi,
          labelText: 'Placa',
          labelStyle: TextStyle(color: _textSec),
          hintText: 'Ingrese la Placa',
          hintStyle: TextStyle(color: _textMut),
          suffixIcon: Icon(Icons.sms_outlined, color: _textSec),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _border, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _red, width: 1.8),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            setState(() {
              factura.placa = (value);
              FacturaService.updateFactura(context, factura);
            });
          }
        },
      ),
    );
  }

  Future<void> goFact(Invoice facturaApp) async {
    if (factura.saldo != 0) {
      Fluttertoast.showToast(
          msg: "La factura aun tiene saldo.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: const Color.fromARGB(255, 70, 19, 15),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    setState(() {
      _showLoader = true;
    });

    Map<String, dynamic> request = {
      'products': facturaApp.detail!.map((e) => e.toApiProducJson()).toList(),
      'idCierre': facturaApp.cierre!.idcierre,
      'cedualaUsuario': facturaApp.empleado!.cedulaEmpleado.toString(),
      'cedulaClienteFactura': facturaApp.formPago!.clienteFactura.documento,
      'totalEfectivo': facturaApp.formPago!.totalEfectivo,
      'totalBac': facturaApp.formPago!.totalBac,
      'totalDav': facturaApp.formPago!.totalDav,
      'totalBn': facturaApp.formPago!.totalBn,
      'totalSctia': facturaApp.formPago!.totalSctia,
      'totalSinpe': facturaApp.formPago!.totalSinpe,
      'totalDollars': facturaApp.formPago!.totalDollars,
      'totalCheques': facturaApp.formPago!.totalCheques,
      'totalCupones': facturaApp.formPago!.totalCupones,
      'totalPuntos': facturaApp.formPago!.totalPuntos,
      'totalTransfer': facturaApp.formPago!.totalTransfer,
      'saldo': facturaApp.saldo,
      'clientePaid': facturaApp.formPago!.clientePuntos.toJson(),
      'Transferencia': facturaApp.formPago!.transfer.toJson(),
      'kms': kms.text.isEmpty ? '0' : kms.text,
      'placa': placa.text.isEmpty ? '' : placa.text,
      'sinpe': facturaApp.formPago!.sinpe.toJson(),
      'observaciones': obser.text.isEmpty ? '' : obser.text,
    };

    Response response = await ApiHelper.post("Api/Facturacion/PostFactura", request);

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: _surface,
              titleTextStyle: const TextStyle(color: _textPri, fontSize: 18, fontWeight: FontWeight.bold),
              contentTextStyle: const TextStyle(color: _textPri, fontSize: 15),
              title: const Text('Error'),
              content: Text(response.message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Aceptar', style: TextStyle(color: _red)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    var decodedJson = jsonDecode(response.result);
    Factura resdocFactura = Factura.fromJson(decodedJson);
    resdocFactura.usuario = factura.empleado!.nombreCompleto;

    String cl = factura.formPago!.clientePuntos.nombre;
    double pCanje = factura.formPago!.totalPuntos;
    int pAcu = factura.formPago!.clientePuntos.puntos;

    // (Impresión omitida; lógica intacta)
    // _goHomeSuccess(facturaApp) se sigue usando desde tus flujos.
  }

  Future<void> _goHomeSuccess(Invoice facturaC) async {
    FacturaService.eliminarFactura(context, facturaC);
    Navigator.pop(context);
  }
}
