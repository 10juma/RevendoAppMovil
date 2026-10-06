import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/sesion.dart';
import '../models/venta.dart';
import '../services/compartir_imagen.dart';
import '../theme.dart';
import '../widgets/ticket_widget.dart';
import 'venta_form_screen.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
final _entero = NumberFormat.decimalPattern('es_MX');
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Comparte el ticket de una venta como imagen (lo usan la tarjeta de la
/// lista y esta pantalla de detalle).
Future<void> compartirTicketVenta(BuildContext context, Sesion sesion, Venta v) {
  final folio = 'V-${v.id.substring(0, 8).toUpperCase()}';
  return compartirWidgetComoImagen(
    context: context,
    nombreArchivo: 'venta_${v.id.substring(0, 8)}',
    textoCompartir: '${sesion.tenantNombre} — $folio',
    widget: TicketWidget(
      negocioNombre: sesion.tenantNombre,
      tipoDocumento: 'Venta',
      folioCorto: folio,
      fecha: _fecha(v.fecha.toLocal()),
      contraparteEtiqueta: 'Cliente',
      contraparteNombre: v.clienteNombre ?? 'Público general',
      lineas: v.items
          .map((i) => TicketLinea(nombre: i.producto, cantidad: i.cantidad, precioUnitario: i.precioUnitario))
          .toList(),
      total: v.total,
      extras: [
        MapEntry('Canal', v.canal),
        MapEntry('Pagada', v.pagada ? 'Sí' : 'No'),
      ],
      nota: v.nota,
    ),
  );
}

/// Detalle de una venta — cliente, almacén, canal, entrega, productos y total.
/// Desde aquí se edita (misma conciliación de inventario que la web) o se
/// comparte el ticket. Regresa `true` si hubo cambios, para que la lista recargue.
class VentaDetalleScreen extends StatelessWidget {
  final Sesion sesion;
  final Venta venta;
  const VentaDetalleScreen({super.key, required this.sesion, required this.venta});

  Future<void> _editar(BuildContext context) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VentaFormScreen(sesion: sesion, venta: venta)),
    );
    if (guardado == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloConIcono(icono: IconosMenu.ventas, texto: 'Detalle de venta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir',
            onPressed: () => compartirTicketVenta(context, sesion, venta),
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
                  venta.clienteNombre ?? 'Público general',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
                const SizedBox(height: 10),
                _fila('Fecha', _fecha(venta.fecha.toLocal())),
                _fila('Almacén', venta.almacenNombre),
                _fila('Canal', venta.canal),
                _fila('Pagada', venta.pagada ? 'Sí' : 'No'),
                _fila('Entrega', venta.estadoEntrega),
                if (venta.usuarioNombre != null) _fila('Registró', venta.usuarioNombre!),
                if (venta.repartidorNombre != null) _fila('Repartidor', venta.repartidorNombre!),
                if (venta.nota != null && venta.nota!.isNotEmpty) _fila('Nota', venta.nota!),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Productos',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          for (final i in venta.items)
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
                          '${_entero.format(i.cantidad)} × ${_moneda.format(i.precioUnitario)}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _moneda.format(i.cantidad * i.precioUnitario),
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
                _moneda.format(venta.total),
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
