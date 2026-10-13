import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import 'ticket_widget.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

class ListaPreciosLinea {
  final String nombre;
  final double precio;

  /// Precio normal (de catálogo) cuando el de la lista es menor — se muestra tachado.
  final double? precioAntes;
  final double? descuentoPorcentaje;
  const ListaPreciosLinea({
    required this.nombre,
    required this.precio,
    this.precioAntes,
    this.descuentoPorcentaje,
  });
}

/// Lista de precios para capturarse como imagen y compartirse (por ejemplo por
/// WhatsApp) — mismo estilo y ancho fijo que [TicketWidget], pero con una fila
/// por producto y su precio, sin cantidades ni total.
class ListaPreciosWidget extends StatelessWidget {
  final String negocioNombre;
  final String nombreLista;
  final String fecha;
  final List<ListaPreciosLinea> lineas;

  const ListaPreciosWidget({
    super.key,
    required this.negocioNombre,
    required this.nombreLista,
    required this.fecha,
    required this.lineas,
  });

  static String _pct(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            negocioNombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Lista de precios · $nombreLista',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentDark),
          ),
          Text(
            fecha,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const LineaPunteada(),
          const SizedBox(height: 12),
          ...lineas.map((l) {
            final partes = <String>[
              if (l.precioAntes != null) 'Antes ${_moneda.format(l.precioAntes)}',
              if (l.descuentoPorcentaje != null) '-${_pct(l.descuentoPorcentaje!)}%',
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.nombre, style: const TextStyle(fontSize: 13.5, color: AppColors.text)),
                        if (partes.isNotEmpty)
                          Text(
                            partes.join(' · '),
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _moneda.format(l.precio),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          const LineaPunteada(),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset('assets/images/logo_1024x1024.jpeg', width: 18, height: 18),
              ),
              const SizedBox(width: 6),
              const Text(
                'Generado con Revendo',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
