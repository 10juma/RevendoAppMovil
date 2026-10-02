import 'package:flutter/material.dart';

/// Un solo lugar para los íconos de cada sección — los usan tanto el menú
/// lateral del Dashboard como el título de cada pantalla, para que siempre
/// coincidan.
class IconosMenu {
  static const dashboard = Icons.dashboard_rounded;
  static const reportes = Icons.bar_chart_rounded;
  static const productos = Icons.inventory_2_outlined;
  static const almacenes = Icons.warehouse_outlined;
  static const existencias = Icons.stacked_bar_chart_rounded;
  static const produccion = Icons.precision_manufacturing_outlined;
  static const proveedores = Icons.local_shipping_outlined;
  static const compras = Icons.shopping_cart_outlined;
  static const gastos = Icons.receipt_long_outlined;
  static const clientes = Icons.people_outline_rounded;
  static const ventas = Icons.point_of_sale_outlined;
  static const listasPrecios = Icons.sell_outlined;
  static const rutas = Icons.alt_route_rounded;
  static const equipo = Icons.group_outlined;
  static const negocio = Icons.storefront_outlined;
}

/// Título de AppBar con el ícono de la sección antes del texto.
class TituloConIcono extends StatelessWidget {
  final IconData icono;
  final String texto;
  const TituloConIcono({super.key, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 22),
        const SizedBox(width: 10),
        Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
