import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Screens/clientes/cliente_frec_screen.dart';
import 'package:tester/constans.dart';

class ClientPoints extends StatefulWidget {
  final Invoice factura;
  final String ruta;

  const ClientPoints({
    super.key,
    required this.factura,
    required this.ruta,
  });

  @override
  State<ClientPoints> createState() => _ClientPointsState();
}

class _ClientPointsState extends State<ClientPoints> {
  @override
  Widget build(BuildContext context) {
    final cliente = widget.factura.formPago?.clientePuntos;
    final nombre = (cliente?.nombre ?? '').trim();
    final puntos = cliente?.puntos ?? 0;
    final hasCliente = nombre.isNotEmpty;

    return Material(
      color: kNewborder,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kTextColorWhite, width: 1),
      ),
      clipBehavior: Clip.antiAlias, // respeta el radio en el ripple
      child: InkWell(
        onTap: _goClientesFrec,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: _leadingAvatar(hasCliente),
          title: Text(
            hasCliente ? "$nombre ($puntos)" : "Seleccione Cliente Frecuente",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
        ),
      ),
    );
  }

  Widget _leadingAvatar(bool hasCliente) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: kContrateFondoOscuro,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: SvgPicture.asset(
        "assets/User Icon.svg",
        // ignore: deprecated_member_use
        color: hasCliente ? kPrimaryColor : kTextColorBlack,
      ),
    );
  }

  Future<void> _goClientesFrec() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientesFrecScreen(
          factura: widget.factura,
          ruta: widget.ruta,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {}); // si cambiaron cliente/puntos, se refleja
  }
}
