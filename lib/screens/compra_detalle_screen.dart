import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/compra.dart';
import '../models/sesion.dart';
import '../services/compartir_imagen.dart';
import '../theme.dart';
import '../widgets/ticket_widget.dart';
import 'compra_form_screen.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
final _entero = NumberFormat.decimalPattern('es_MX');
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Comparte el ticket de una compra como imagen (lo usan la tarjeta de la
/// lista y esta pantalla de detalle).
Future<void> compartirTicketCompra(BuildContext context, Sesion sesion, Compra c) {
  final folio = 'C-${c.id.substring(0, 8).toUpperCase()}';
  return compartirWidgetComoImagen(
    context: context,
    nombreArchivo: 'compra_${c.id.substring(0, 8)}',
    textoCompartir: '${sesion.tenantNombre} — $folio',
    widget: TicketWidget(
      negocioNombre: sesion.tenantNombre,
      tipoDocumento: 'Compra',
      folioCorto: folio,
      fecha: _fecha(c.fecha.toLocal()),
      contraparteEtiqueta: 'Proveedor',
      contraparteNombre: c.proveedorNombre,
      lineas: c.items
          .map((i) => TicketLinea(nombre: i.producto, cantidad: i.cantidad, precioUnitario: i.costoUnitario))
          .toList(),
      total: c.total,
      extras: [MapEntry('Almacén', c.almacenNombre)],
      nota: c.nota,
    ),
  );
}

/// Detalle de una compra — proveedor, almacén, productos y total. Desde aquí
/// se edita (misma lógica de conciliación de inventario que la web) o se
/// comparte el ticket. Regresa `true` si hubo cambios, para que la lista recargue.
class CompraDetalleScreen extends StatelessWidget {
  final Sesion sesion;
  final Compra compra;
  const CompraDetalleScreen({super.key, required this.sesion, required this.compra});

  Future<void> _editar(BuildContext context) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CompraFormScreen(sesion: sesion, compra: compra)),
    );
    if (guardado == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloConIcono(icono: IconosMenu.compras, texto: 'Detalle de compra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir',
            onPressed: () => compartirTicketCompra(context, sesion, compra),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => _editar(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compra.proveedorNombre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
                const SizedBox(height: 10),
                _fila('Fecha', _fecha(compra.fecha.toLocal())),
                _fila('Almacén', compra.almacenNombre),
                if (compra.nota != null && compra.nota!.isNotEmpty) _fila('Nota', compra.nota!),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Productos',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          for (final i in compra.items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.producto,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                        ),
                        Text(
                          '${_entero.format(i.cantidad)} × ${_moneda.format(i.costoUnitario)}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _moneda.format(i.cantidad * i.costoUnitario),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                _moneda.format(compra.total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                valor,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
            ),
          ],
        ),
      );
}
