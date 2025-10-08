import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/client_card.dart';
import 'package:tester/Components/color_button.dart';
import 'package:tester/Components/custom_surfix_icon.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';

class ClientesFrecScreen extends StatefulWidget {
  final Invoice factura;
  final String ruta;

  const ClientesFrecScreen({
    super.key,
    required this.factura,
    required this.ruta,
  });

  @override
  State<ClientesFrecScreen> createState() => _ClientesFrecScreenState();
}

class _ClientesFrecScreenState extends State<ClientesFrecScreen> {
  // Paleta oscura con alto contraste
  static const Color _card     = Color(0xFF1E2430); // superficie de card
  static const Color _field    = Color(0xFF141A22); // fondo del input
  static const Color _onBg     = Color(0xF2FFFFFF); // texto principal (~95% blanco)
  static const Color _onSubtle = Color(0xB3FFFFFF); // texto secundario (~70% blanco)
  static const Color _border   = Color(0x3DFFFFFF); // borde tenue (~24% blanco)

  final _formKey = GlobalKey<FormState>();
  final TextEditingController documentController = TextEditingController();
  bool _showLoader = false;

  @override
  void dispose() {
    documentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kColorFondoOscuro,
        appBar: const MyCustomAppBar(
          title: 'Buscar Cliente Frecuente',
          elevation: 6,
          shadowColor: kColorFondoOscuro,
          automaticallyImplyLeading: true,
          foreColor: Colors.white,
          backgroundColor: kPrimaryColor,
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ClipOval(
                child: Image(
                  image: AssetImage('assets/splash.png'),
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _body(),
            _showLoader ? const LoaderComponent(loadingText: 'Buscando...') : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final hasResult = widget.factura.formPago!.clientePuntos.nombre.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 720 ? 640.0 : double.infinity;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(20),
                  vertical: SizeConfig.screenHeight * 0.04,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _searchCard(),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: hasResult ? _resultCard() : _emptyState(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _searchCard() {
    return Card(
      color: _card,
      elevation: 6,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Digite el código del cliente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _onBg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: documentController,
                maxLength: 7,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: _onBg),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  hintText: 'Ingresa el código',
                  labelText: 'Código Cliente',
                  counterText: '',
                  filled: true,
                  fillColor: _field,
                  labelStyle: const TextStyle(color: _onSubtle),
                  hintStyle: const TextStyle(color: _onSubtle),
                  errorMaxLines: 2,
                  suffixIcon: const CustomSurffixIcon(svgIcon: "assets/receipt.svg"),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimaryColor, width: 1.4),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                  ),
                ),
                validator: _validateCodigo,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ColorButton(
                  text: "Buscar",
                  press: _getClient,
                  ancho: 120,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: _onSubtle),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ingresa un código y presiona “Buscar”.',
              style: TextStyle(color: _onSubtle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final cliente = widget.factura.formPago!.clientePuntos;

    return Card(
      color: _card,
      elevation: 6,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: _onBg,
                  displayColor: _onBg,
                ),
                iconTheme: const IconThemeData(color: _onBg),
                cardColor: _card,
              ),
              child: ClientCard(client: cliente),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: getProportionateScreenWidth(140),
              child: DefaultButton(
                text: 'Select',
                press: _goCheckOut,
                gradient: kPrimaryGradientColor,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateCodigo(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Debes ingresar un código.';
    if (v.length != 7) return 'El código debe tener exactamente 7 dígitos.';
    if (!RegExp(r'^\d{7}$').hasMatch(v)) return 'Solo dígitos (0–9).';
    return null;
  }

  Future<void> _getClient() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _showLoader = true);

    final Response response = await ApiHelper.getClientFrec(documentController.text.trim());

    setState(() => _showLoader = false);

    if (!response.isSuccess) {
      Fluttertoast.showToast(
        msg: "No Encontrado",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() {
      widget.factura.formPago!.clientePuntos = response.result;
    });
  }

  void _goCheckOut() {
    FacturaService.updateFactura(context, widget.factura);
    Navigator.pop(context);
  }
}
