import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Screens/clientes/cliestes_new_screen.dart'; // verifica el nombre real del archivo
import 'package:tester/constans.dart';

class ShowClient extends StatefulWidget {
  final Invoice factura;  
  final EdgeInsets? padding;
   final ClienteTipo tipo;

  const ShowClient({
    super.key,
    required this.factura,    
    this.padding,
    required this.tipo,
  });

  @override
  State<ShowClient> createState() => _ShowClientState();
}

class _ShowClientState extends State<ShowClient> {
  @override
  Widget build(BuildContext context) {
    final nombre = (widget.factura.formPago?.clienteFactura.nombre ?? '').trim();
    final hasCliente = nombre.isNotEmpty;

    // Compacto, sin contenedor externo, solo NOMBRE
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Material(
        color: kColorFondoOscuro,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kTextColorWhite, width: 1),
      ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _goClientes,
          borderRadius: BorderRadius.circular(10),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: _leadingAvatar(hasCliente),
            title: Text(
              hasCliente ? nombre : "Seleccione un cliente",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,

              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: kContrateFondoOscuro),
          ),
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

  Future<void> _goClientes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientesNewScreen(
          tipo: widget.tipo,
          factura: widget.factura,
         
        ),
      ),
    );
    if (!mounted) return;
    setState(() {}); // refresca el nombre si cambió en la factura
  }
}
