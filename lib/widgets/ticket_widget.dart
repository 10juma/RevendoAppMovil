import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
final _entero = NumberFormat.decimalPattern('es_MX');

class TicketLinea {
  final String nombre;
  final double cantidad;
  final double precioUnitario;
  const TicketLinea({required this.nombre, required this.cantidad, required this.precioUnitario});
}

/// Ticket/voucher de una venta o compra, pensado para capturarse como
/// imagen y compartirse (por ejemplo por WhatsApp) — no es una pantalla, es
/// un layout de ancho fijo tipo recibo.
class TicketWidget extends StatelessWidget {
  final String negocioNombre;
  final String tipoDocumento;
  final String folioCorto;
  final String fecha;
  final String? contraparteEtiqueta;
  final String? contraparteNombre;
  final List<TicketLinea> lineas;
  final double total;
  final List<MapEntry<String, String>> extras;
  final String? nota;

  const TicketWidget({
    super.key,
    required this.negocioNombre,
    required this.tipoDocumento,
    required this.folioCorto,
    required this.fecha,
    this.contraparteEtiqueta,
    this.contraparteNombre,
    required this.lineas,
    required this.total,
    this.extras = const [],
    this.nota,
  });

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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$tipoDocumento · $folioCorto',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accentDark,
            ),
          ),
          Text(
            fecha,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const _LineaPunteada(),
          const SizedBox(height: 12),
          if (contraparteNombre != null) ...[
            _filaExtra(contraparteEtiqueta ?? '', contraparteNombre!),
            const SizedBox(height: 4),
          ],
          ...extras.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _filaExtra(e.key, e.value),
              )),
          const SizedBox(height: 8),
          const _LineaPunteada(),
          const SizedBox(height: 12),
          ...lineas.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.nombre,
                            style: const TextStyle(fontSize: 13.5, color: AppColors.text),
                          ),
                          Text(
                            '${_entero.format(l.cantidad)} × ${_moneda.format(l.precioUnitario)}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _moneda.format(l.cantidad * l.precioUnitario),
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          const _LineaPunteada(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
              Text(
                _moneda.format(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentDark),
              ),
            ],
          ),
          if (nota != null && nota!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              nota!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 22),
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

  Widget _filaExtra(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

class _LineaPunteada extends StatelessWidget {
  const _LineaPunteada();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cantidad = (constraints.maxWidth / 6).floor();
          return Row(
            children: List.generate(
              cantidad,
              (_) => const Expanded(
                child: SizedBox(height: 1, child: ColoredBox(color: AppColors.border)),
              ),
            ).expand((w) => [w, const SizedBox(width: 3)]).toList(),
          );
        },
      ),
    );
  }
}
