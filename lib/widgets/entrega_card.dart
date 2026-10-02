import 'package:flutter/material.dart';

import '../models/entrega.dart';
import '../theme.dart';

/// Mismo diseño que `.entrega-card` en admin.css — nombre del cliente + badge
/// de estado arriba, dirección/teléfono/almacén en gris, lista de productos
/// sin precios, y el botón de avanzar estado si aplica.
class EntregaCard extends StatelessWidget {
  final Entrega entrega;
  final bool actualizando;
  final VoidCallback? onAvanzar;

  const EntregaCard({
    super.key,
    required this.entrega,
    required this.actualizando,
    this.onAvanzar,
  });

  Color get _badgeBg => entrega.estadoEntrega == 'EnRuta'
      ? AppColors.badgeActiveBg
      : AppColors.bg;

  Color get _badgeTexto => entrega.estadoEntrega == 'EnRuta'
      ? AppColors.accentDark
      : AppColors.textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entrega.clienteNombre ?? 'Sin cliente',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entrega.etiquetaEstado,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _badgeTexto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if ((entrega.clienteDireccion ?? '').isNotEmpty)
            _metaLinea('Dirección: ${entrega.clienteDireccion}'),
          if ((entrega.clienteTelefono ?? '').isNotEmpty)
            _metaLinea('Teléfono: ${entrega.clienteTelefono}'),
          _metaLinea('Recoger en: ${entrega.almacenNombre}'),
          const SizedBox(height: 8),
          ...entrega.items.map(
            (it) => Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: .75),
                ),
              ),
              child: Text(
                '${_fmtCantidad(it.cantidad)} x ${it.producto}',
                style: const TextStyle(fontSize: 14, color: AppColors.text),
              ),
            ),
          ),
          if (onAvanzar != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: actualizando ? null : onAvanzar,
                child: actualizando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(entrega.etiquetaAccion),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaLinea(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
    ),
  );

  String _fmtCantidad(double c) {
    if (c == c.roundToDouble()) return c.toInt().toString();
    var s = c.toStringAsFixed(3);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }
}
